# frozen_string_literal: true

require 'open3'
require 'json'

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleStyle
          # Runs RuboCop or StandardRB on code snippets and returns offenses
          class RubocopRunner
            # @param linter [Symbol] which linter to use (:rubocop or :standard)
            # @param disabled_cops [Array<String>] list of cop names to disable
            # @param skip_patterns [Array<String>] regex patterns to skip examples
            def initialize(linter:, disabled_cops: [], skip_patterns: [])
              @linter = linter
              @disabled_cops = disabled_cops
              @skip_patterns = compile_patterns(skip_patterns)
            end

            # Run linter on code example and return offenses
            # @param code [String] Ruby code extracted from @example tag to check for style violations
            # @param example_name [String] name of the example for context
            # @return [Array<Hash>] array of offense hashes with :cop_name, :message, :line, :column keys
            def run(code, example_name)
              return [] if should_skip?(example_name)

              cleaned_code = clean_code(code)
              return [] if cleaned_code.empty?

              case @linter
              when :rubocop
                run_rubocop(cleaned_code)
              when :standard
                run_standard(cleaned_code)
              else
                []
              end
            rescue StandardError => e
              warn "[YARD::Lint] ExampleStyle: Error running #{@linter}: #{e.message}" if ENV['DEBUG']
              []
            end

            private

            # Compile skip patterns into regex objects
            # @param patterns [Array<String>] array of regex pattern strings
            # @return [Array<Regexp>] array of compiled regex objects
            def compile_patterns(patterns)
              patterns.filter_map do |pattern|
                # Pattern format: '/pattern/flags' or 'pattern'
                if pattern.start_with?('/') && pattern.match?(%r{^/(.+)/([imx]*)$})
                  match = pattern.match(%r{^/(.+)/([imx]*)$})
                  Regexp.new(match[1], parse_flags(match[2]))
                else
                  Regexp.new(pattern)
                end
              rescue RegexpError => e
                warn "[YARD::Lint] ExampleStyle: Invalid skip pattern '#{pattern}': #{e.message}" if ENV['DEBUG']
                nil
              end
            end

            # Parse regex flags from string
            # @param flags_str [String] flags string like 'i' or 'im'
            # @return [Integer] OR'd flag constants
            def parse_flags(flags_str)
              flags = 0
              flags |= Regexp::IGNORECASE if flags_str.include?('i')
              flags |= Regexp::MULTILINE if flags_str.include?('m')
              flags |= Regexp::EXTENDED if flags_str.include?('x')
              flags
            end

            # Check if example should be skipped based on skip patterns
            # @param example_name [String] name of the example
            # @return [Boolean] true if should skip
            def should_skip?(example_name)
              @skip_patterns.any? { |pattern| example_name.match?(pattern) }
            end

            # Clean code by removing output indicators and extra whitespace
            # Mirrors the logic from ExampleSyntax validator
            # @param code [String] raw code from @example tag
            # @return [String] cleaned code
            def clean_code(code)
              return '' if code.nil? || code.empty?

              # Strip output indicators (#=>) and everything after it
              code_lines = code.split("\n").map do |line|
                line.sub(/\s*#\s*=>.*$/, '')
              end

              code_lines.join("\n").strip
            end

            # Run RuboCop on code and parse JSON output
            # @param code [String] Ruby code snippet to analyze with RuboCop
            # @return [Array<Hash>] array of offense hashes
            def run_rubocop(code)
              # Build RuboCop command
              cmd = ['rubocop', '--format', 'json', '--stdin', 'example.rb']

              # Add disabled cops
              @disabled_cops.each do |cop|
                cmd += ['--except', cop]
              end

              stdout, = Open3.capture3(*cmd, stdin_data: code)

              # RuboCop returns non-zero exit status when offenses are found
              # We only care about actual errors (not offense findings)
              return [] if stdout.empty?

              parse_rubocop_output(stdout)
            rescue Errno::ENOENT
              warn '[YARD::Lint] ExampleStyle: rubocop command not found' if ENV['DEBUG']
              []
            end

            # Run StandardRB on code and parse JSON output
            # @param code [String] Ruby code snippet to analyze with StandardRB
            # @return [Array<Hash>] array of offense hashes
            def run_standard(code)
              # StandardRB doesn't support --except for individual cops
              # Users must configure exclusions in .standard.yml
              cmd = ['standardrb', '--format', 'json', '--stdin', 'example.rb']

              stdout, = Open3.capture3(*cmd, stdin_data: code)

              # StandardRB returns non-zero exit status when offenses are found
              return [] if stdout.empty?

              parse_rubocop_output(stdout) # StandardRB uses RuboCop's JSON format
            rescue Errno::ENOENT
              warn '[YARD::Lint] ExampleStyle: standardrb command not found' if ENV['DEBUG']
              []
            end

            # Parse RuboCop/StandardRB JSON output
            # @param json_output [String] JSON output from linter
            # @return [Array<Hash>] array of offense hashes
            def parse_rubocop_output(json_output)
              result = JSON.parse(json_output)

              # RuboCop JSON format: { "files": [ { "offenses": [...] } ] }
              files = result['files'] || []
              return [] if files.empty?

              file = files.first
              offenses = file['offenses'] || []

              offenses.map do |offense|
                {
                  cop_name: offense['cop_name'],
                  message: offense['message'],
                  line: offense['location']['line'],
                  column: offense['location']['column'],
                  severity: offense['severity']
                }
              end
            rescue JSON::ParserError => e
              warn "[YARD::Lint] ExampleStyle: Failed to parse linter output: #{e.message}" if ENV['DEBUG']
              []
            end
          end
        end
      end
    end
  end
end
