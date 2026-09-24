# frozen_string_literal: true

require 'json'
require 'pathname'
require 'digest'

module Yard
  module Lint
    module Formatters
      # Renders lint results as SARIF 2.1.0 (Static Analysis Results Interchange
      # Format) - the JSON format GitHub code scanning and other result aggregators
      # ingest, so yard-lint offenses can surface as PR annotations / Security-tab
      # alerts instead of being buried in CI logs.
      #
      # This is output only: it does not change which offenses are reported, the
      # exit code, or any configuration - it is an alternative rendering of the
      # same result. Rule metadata (`rules[]`) is populated from each validator's
      # own YARD documentation via {Explainer.describe}.
      class Sarif
        # SARIF 2.1.0 JSON schema URI, emitted as the document's `$schema`.
        # @return [String]
        SCHEMA_URI = 'https://json.schemastore.org/sarif-2.1.0.json'

        # Tool information URI, emitted as the driver's `informationUri`.
        # @return [String]
        INFORMATION_URI = 'https://github.com/mensfeld/yard-lint'

        # Help URI for each rule (the wiki validator reference).
        # @return [String]
        HELP_URI = 'https://github.com/mensfeld/yard-lint/wiki/Validators'

        # SARIF supports only error/warning/note (plus none). yard-lint's
        # `convention` maps to note, and `never` (report-only) maps to none.
        # @return [Hash{String => String}]
        SEVERITY_LEVELS = {
          'error' => 'error',
          'warning' => 'warning',
          'convention' => 'note',
          'never' => 'none'
        }.freeze

        # Fallback SARIF level for any unrecognized severity.
        # @return [String]
        DEFAULT_LEVEL = 'warning'

        # partialFingerprints key, versioned so the scheme can evolve without
        # invalidating history. GitHub uses it to correlate results across runs.
        # @return [String]
        FINGERPRINT_KEY = 'yardLintOffense/v1'

        # @param offenses [Array<Hash>] offense hashes (from `result.offenses`)
        # @param base_dir [String] directory that offense paths are made relative
        #   to, so GitHub can map them onto the repository (default: current dir)
        def initialize(offenses, base_dir: Dir.pwd)
          @offenses = offenses
          @base_dir = base_dir
        end

        # @return [String] pretty-printed SARIF 2.1.0 JSON
        def generate
          JSON.pretty_generate(document)
        end

        # @return [Hash] the SARIF document as a Ruby hash
        def document
          rule_ids = @offenses.map { |offense| offense[:validator] }.compact.uniq
          rule_index = rule_ids.each_with_index.to_h

          {
            '$schema' => SCHEMA_URI,
            'version' => '2.1.0',
            'runs' => [
              {
                'tool' => { 'driver' => driver(rule_ids) },
                'results' => @offenses.map { |offense| result(offense, rule_index) }
              }
            ]
          }
        end

        private

        # @param rule_ids [Array<String>] distinct validator names, in result order
        # @return [Hash] the SARIF tool driver, including rule metadata
        def driver(rule_ids)
          {
            'name' => 'yard-lint',
            'informationUri' => INFORMATION_URI,
            'version' => Yard::Lint::VERSION,
            'rules' => rule_ids.map { |id| rule(id) }
          }
        end

        # @param id [String] validator name (e.g. 'Tags/TypeSyntax')
        # @return [Hash] a SARIF reportingDescriptor for the validator
        def rule(id)
          entry = {
            'id' => id,
            'name' => id.split('/').last,
            'helpUri' => HELP_URI,
            'defaultConfiguration' => { 'level' => level(default_severity(id)) }
          }

          described = Explainer.describe(id)
          if described
            entry['shortDescription'] = { 'text' => described[:short] }
            entry['fullDescription'] = { 'text' => described[:full] }
          end

          entry
        end

        # @param offense [Hash] an offense hash
        # @param rule_index [Hash{String => Integer}] validator name to rule index
        # @return [Hash] a SARIF result
        def result(offense, rule_index)
          uri = relative_uri(offense[:location])
          entry = {}

          # ruleId/ruleIndex are optional in SARIF; omit them (rather than emit
          # null, which is schema-invalid) for the rare offense with no validator.
          validator = offense[:validator]
          if validator
            entry['ruleId'] = validator
            entry['ruleIndex'] = rule_index[validator]
          end

          entry['level'] = level(offense[:severity])
          entry['message'] = { 'text' => offense[:message].to_s }
          entry['locations'] = [location(offense, uri)]
          entry['partialFingerprints'] = { FINGERPRINT_KEY => fingerprint(offense, uri) }
          entry
        end

        # @param offense [Hash] an offense hash
        # @param uri [String] the artifact URI (already made relative)
        # @return [Hash] a SARIF location
        def location(offense, uri)
          {
            'physicalLocation' => {
              'artifactLocation' => { 'uri' => uri },
              'region' => { 'startLine' => start_line(offense) }
            }
          }
        end

        # A line-independent fingerprint so GitHub correlates the same offense
        # across commits without churn (close/reopen) when unrelated lines shift.
        # Keys on the validator, file, and offending object; the line number and
        # message text are excluded so a re-worded message does not churn alerts.
        # @param offense [Hash] an offense hash
        # @param uri [String] the artifact URI (already made relative)
        # @return [String] a stable hex digest
        def fingerprint(offense, uri)
          parts = [offense[:validator], uri, offense[:element]]
          Digest::SHA256.hexdigest(parts.map(&:to_s).join("\x00"))
        end

        # @param severity [String, nil] a yard-lint severity
        # @return [String] the SARIF level
        def level(severity)
          SEVERITY_LEVELS.fetch(severity.to_s, DEFAULT_LEVEL)
        end

        # SARIF regions are 1-based; guard against a missing or zero line.
        # @param offense [Hash] an offense hash
        # @return [Integer] a 1-based start line
        def start_line(offense)
          line = (offense[:location_line] || offense[:line]).to_i
          line.positive? ? line : 1
        end

        # Make a path repository-relative so GitHub maps it onto a file. Paths
        # already relative are kept; a path outside base_dir keeps its original
        # value rather than emitting a `../` or absolute URI.
        # @param location [String, nil] the offense location path
        # @return [String] a relative URI where possible
        def relative_uri(location)
          path = location.to_s
          return path if path.empty?

          absolute = File.absolute_path(path, @base_dir)
          relative = Pathname.new(absolute).relative_path_from(Pathname.new(@base_dir)).to_s
          relative.start_with?('..') ? path : relative
        rescue ArgumentError
          # relative_path_from raises across platforms/mixed roots; fall back.
          path
        end

        # The validator's default severity, from a defaults-only config, for the
        # rule's defaultConfiguration.level.
        # @param id [String] validator name
        # @return [String] default severity
        def default_severity(id)
          @default_config ||= Config.new
          @default_config.validator_severity(id)
        end
      end
    end
  end
end
