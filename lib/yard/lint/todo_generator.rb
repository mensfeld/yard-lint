# frozen_string_literal: true

module Yard
  module Lint
    # Generates .yard-lint-todo.yml file with exclusions for current violations
    class TodoGenerator
      # Default grouping threshold (15+ files triggers pattern grouping)
      DEFAULT_EXCLUDE_LIMIT = 15

      class << self
        # Generate .yard-lint-todo.yml file with exclusions for current violations
        # @param path [String] directory or file path containing Ruby files to analyze for violations
        # @param config [Config] yard-lint configuration object with validator settings
        # @param force [Boolean] whether to overwrite existing todo file if present
        # @param exclude_limit [Integer] minimum files in directory before grouping into wildcard patterns
        # @param config_path [String, nil] config file to link the todo into
        #   (defaults to .yard-lint.yml in the current directory)
        # @return [Hash] result with :message, :offense_count, :validator_count
        def generate(path:, config:, force: false, exclude_limit: DEFAULT_EXCLUDE_LIMIT, config_path: nil)
          new(path: path, config: config, force: force, exclude_limit: exclude_limit,
              config_path: config_path).generate
        end

        # Report .yard-lint-todo.yml Exclude entries that no longer match any offense
        # @param path [String] directory or file path containing Ruby files to analyze for violations
        # @param config [Config] yard-lint configuration object with validator settings
        # @return [Hash] result with :message and :unused_entries (validator name => unused patterns)
        def check(path:, config:)
          new(path: path, config: config, force: false, exclude_limit: DEFAULT_EXCLUDE_LIMIT).check
        end
      end

      # Initialize a new TodoGenerator instance
      # @param path [String] directory or file path containing Ruby files to analyze
      # @param config [Config] yard-lint configuration object
      # @param force [Boolean] whether to overwrite existing todo file
      # @param exclude_limit [Integer] minimum files before grouping into patterns
      # @param config_path [String, nil] config file to link the todo into
      def initialize(path:, config:, force:, exclude_limit:, config_path: nil)
        @path = path
        @config = config
        @force = force
        @exclude_limit = exclude_limit
        @todo_path = File.join(Dir.pwd, '.yard-lint-todo.yml')
        @config_path = config_path || File.join(Dir.pwd, Config::DEFAULT_CONFIG_FILE)
      end

      # Generate the .yard-lint-todo.yml file with exclusions for current violations
      # @return [Hash] result hash with :message, :offense_count, :validator_count keys
      def generate
        # Step 1: Check if todo file exists
        validate_todo_file_not_exists! unless @force

        # Step 2: Run linting to collect violations
        lint_result = run_linting

        # Step 3: Handle clean codebase
        return no_violations_result if lint_result[:violations_by_validator].empty?

        # Step 4: Group violations by validator
        violations_by_validator = group_violations_by_validator(lint_result)

        # Step 5: Generate todo YAML content
        todo_content = build_todo_yaml(violations_by_validator)

        # Step 6: Write todo file
        File.write(@todo_path, todo_content)

        # Step 7: Update main config to inherit todo file
        update_main_config

        # Step 8: Build success message
        build_success_result(violations_by_validator, lint_result[:total_offenses])
      end

      # Re-lint without the todo file exclusions and find entries that match no offense
      # Offenses can depend on the other linted files and on their order, so an entry counts as
      # used when it matches an offense of a whole-project run or of a run on the path only.
      # The path only limits which entries are judged: those that cover a file under it,
      # or no project file at all. The given config is not modified.
      # @return [Hash] result with :message and :unused_entries (validator name => unused patterns)
      # @raise [Errors::TodoFileNotFoundError] if the todo file does not exist
      def check
        todo_entries = load_todo_entries
        audit_config = build_audit_config(todo_entries)
        path_files = Yard::Lint.send(:expand_path, @path, audit_config)
        files = Yard::Lint.send(:expand_path, '.', audit_config) | path_files

        violations_by_validator = audit_violations([files, path_files], audit_config)
        files = files.map { |file| make_relative_path(file) }
        path_files = path_files.map { |file| make_relative_path(file) }

        unused_entries = todo_entries.each_with_object({}) do |(validator_name, patterns), unused|
          next unless judged?(validator_name, audit_config)

          violating_files = violations_by_validator.fetch(validator_name, [])
          stale = patterns.select do |pattern|
            in_scope?(pattern, files, path_files) && violating_files.none? { |file| todo_match?(pattern, file) }
          end
          unused[validator_name] = stale if stale.any?
        end

        { message: build_check_message(unused_entries), unused_entries: unused_entries }
      end

      private

      # Load per-validator Exclude patterns from the todo file
      # @return [Hash{String => Array<String>}] validator names to their todo Exclude patterns
      # @raise [Errors::TodoFileNotFoundError] if the todo file does not exist
      def load_todo_entries
        unless File.exist?(@todo_path)
          raise Errors::TodoFileNotFoundError,
            '.yard-lint-todo.yml not found. Use --auto-gen-config to generate it.'
        end

        ConfigLoader.load_yaml_file(@todo_path).each_with_object({}) do |(validator_name, settings), entries|
          next unless settings.is_a?(Hash) && settings['Exclude'].is_a?(Array)

          entries[validator_name] = settings['Exclude'].map(&:to_s)
        end
      end

      # Build a copy of the config without the todo file's Exclude lists
      # A per-validator Exclude replaces an inherited one, so a validator's todo list is in effect
      # only when it is that validator's whole Exclude. Otherwise the user's Exclude stays as is.
      # @param todo_entries [Hash{String => Array<String>}] validator names to todo Exclude patterns
      # @return [Config] configuration for the audit run
      def build_audit_config(todo_entries)
        audit_config = Config.new(Marshal.load(Marshal.dump(@config.raw_config)))
        audit_config.base_dir = @config.base_dir
        audit_config.only_validators = @config.only_validators.dup

        todo_entries.each do |validator_name, patterns|
          next unless ConfigLoader::ALL_VALIDATORS.include?(validator_name)
          next unless audit_config.validator_config(validator_name, 'Exclude') == patterns

          audit_config.set_validator_config(validator_name, 'Exclude', [])
        end

        audit_config
      end

      # Lint each file set and merge the violating files per validator
      # @param file_sets [Array<Array<String>>] file sets to lint separately
      # @param config [Config] configuration for the audit run
      # @return [Hash{String => Array<String>}] validator names to files with offenses in any run
      def audit_violations(file_sets, config)
        file_sets.uniq(&:sort).each_with_object({}) do |files, merged|
          run_linting(files: files, config: config)[:violations_by_validator].each do |validator_name, paths|
            merged[validator_name] = merged.fetch(validator_name, []) | paths
          end
        end
      end

      # Whether the audit can judge a validator's todo entries
      # Entries of validators left out by only_validators are not judged, as they were not run.
      # @param validator_name [String] validator name from the todo file
      # @param config [Config] configuration for the audit run
      # @return [Boolean] true unless only_validators leaves the validator out
      def judged?(validator_name, config)
        config.only_validators.empty? || config.only_validators.include?(validator_name)
      end

      # Whether a todo pattern belongs to the checked path
      # @param pattern [String] todo Exclude pattern
      # @param files [Array<String>] relative paths of all linted files
      # @param path_files [Array<String>] relative paths of the files under the checked path
      # @return [Boolean] true if the pattern covers a file under the path, or no linted file at all
      def in_scope?(pattern, files, path_files)
        path_files.any? { |file| todo_match?(pattern, file) } ||
          files.none? { |file| todo_match?(pattern, file) }
      end

      # Whether a todo Exclude pattern matches a file
      # @param pattern [String] todo Exclude pattern
      # @param file [String] relative file path
      # @return [Boolean] true if the pattern matches the file
      def todo_match?(pattern, file)
        File.fnmatch(pattern, file, File::FNM_PATHNAME | File::FNM_EXTGLOB)
      end

      # Build the summary message for a todo check
      # @param unused_entries [Hash{String => Array<String>}] validator names to unused patterns
      # @return [String] human-readable summary
      def build_check_message(unused_entries)
        return 'No unused entries found in .yard-lint-todo.yml' if unused_entries.empty?

        count = unused_entries.values.sum(&:size)
        lines = ["Found #{count} unused entr#{count == 1 ? 'y' : 'ies'} in .yard-lint-todo.yml:"]
        unused_entries.each do |validator_name, patterns|
          lines << "  #{validator_name}:"
          patterns.each { |pattern| lines << "    - '#{pattern}'" }
        end
        lines << ''
        lines << 'Remove these entries, or run yard-lint --regenerate-todo to rebuild the file.'
        lines.join("\n")
      end

      # Validate that the todo file doesn't already exist
      # @return [void]
      # @raise [Errors::TodoFileExistsError] if todo file exists and force is false
      def validate_todo_file_not_exists!
        return unless File.exist?(@todo_path)

        raise Errors::TodoFileExistsError,
          '.yard-lint-todo.yml already exists. Use --regenerate-todo to overwrite.'
      end

      # Run linting and collect violations per validator
      # @param files [Array<String>, nil] files to lint (defaults to the files under the path)
      # @param config [Config] configuration to lint with
      # @return [Hash] hash with :violations_by_validator and :total_offenses keys
      def run_linting(files: nil, config: @config)
        # Run each validator individually to track violations per validator
        # This is more reliable than trying to infer validator from offense name
        files ||= Yard::Lint.send(:expand_path, @path, config)
        runner = Runner.new(files, config)

        # Run validators and collect raw results
        raw_results = runner.send(:run_validators)
        result_builder = ResultBuilder.new(config)

        violations_by_validator = {}
        total_offenses = 0

        # Process each validator's results
        ConfigLoader::ALL_VALIDATORS.each do |validator_name|
          next unless config.validator_enabled?(validator_name)

          validator_result = result_builder.build(validator_name, raw_results)
          next unless validator_result

          # Apply per-validator Exclude patterns (and drop no-location offenses)
          # exactly as a normal run does, so the baseline does not silence files
          # that are already excluded.
          validator_result = runner.send(:filter_result_offenses, validator_name, validator_result)
          next unless validator_result && validator_result.offenses.any?

          # Extract file paths from offenses, skipping those without a location
          file_paths = validator_result.offenses.filter_map do |offense|
            make_relative_path(offense[:location])
          end.uniq.sort

          violations_by_validator[validator_name] = file_paths
          total_offenses += validator_result.count
        end

        { violations_by_validator: violations_by_validator, total_offenses: total_offenses }
      end

      # Build result hash for when no violations are found
      # @return [Hash] result indicating clean codebase
      def no_violations_result
        {
          message: "No offenses found. No .yard-lint-todo.yml needed.\nYour codebase is already compliant!",
          offense_count: 0,
          validator_count: 0
        }
      end

      # Apply path grouping to each validator's file list
      # @param lint_result [Hash] hash containing violations_by_validator data
      # @return [Hash] hash of validator names to grouped file patterns
      def group_violations_by_validator(lint_result)
        # Apply path grouping to each validator's file list
        lint_result[:violations_by_validator].transform_values do |files|
          PathGrouper.group(files, limit: @exclude_limit)
        end
      end

      # Convert a path to the form Exclude patterns match (relative to the config directory)
      # @param path [String, nil] absolute or relative file path
      # @return [String, nil] path relative to the config directory, or nil if path is nil
      def make_relative_path(path)
        return path if path.nil?

        @config.relative_path(path)
      end

      # Build YAML content for the todo file
      # @param violations_by_validator [Hash] hash of validator names to file patterns
      # @return [String] formatted YAML content
      def build_todo_yaml(violations_by_validator)
        lines = []

        # Header
        lines << "# This file was auto-generated by yard-lint --auto-gen-config on #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC')}"
        lines << '# It contains exclusions for all current violations to establish a baseline.'
        lines << '#'
        lines << '# To gradually fix violations:'
        lines << '# 1. Remove files/patterns from the Exclude list below'
        lines << '# 2. Run yard-lint to see the violations for those files'
        lines << '# 3. Fix the violations'
        lines << '# 4. Commit the changes'
        lines << '#'
        lines << '# To regenerate this file, run: yard-lint --regenerate-todo'
        lines << ''

        # Group validators by category
        categories = group_by_category(violations_by_validator)

        # Write each category
        ConfigUpdater::CATEGORY_ORDER.each do |category|
          validators = categories[category]
          next unless validators&.any?

          lines << ConfigUpdater::CATEGORY_COMMENTS[category] if ConfigUpdater::CATEGORY_COMMENTS[category]

          validators.each do |validator_name, file_patterns|
            lines << "#{validator_name}:"
            lines << '  Exclude:'
            file_patterns.each do |pattern|
              lines << "    - '#{pattern}'"
            end
            lines << ''
          end
        end

        lines.join("\n")
      end

      # Group validators by their category (Documentation, Tags, etc.)
      # @param violations_by_validator [Hash] hash of validator names to patterns
      # @return [Hash] validators grouped by category
      def group_by_category(violations_by_validator)
        categories = Hash.new { |h, k| h[k] = {} }

        violations_by_validator.each do |validator_name, patterns|
          category = validator_name.split('/').first
          categories[category][validator_name] = patterns
        end

        categories
      end

      # Update or create main config file to inherit from todo file
      # @return [void]
      def update_main_config
        if File.exist?(@config_path)
          update_existing_config
        else
          create_minimal_config
        end
      end

      # Update existing config file to add inherit_from todo file
      # @return [void]
      def update_existing_config
        config_yaml = ConfigLoader.load_yaml_file(@config_path)
        return if Array(config_yaml['inherit_from']).include?('.yard-lint-todo.yml')

        raw = File.read(@config_path)

        # Edit the file textually rather than round-tripping through to_yaml,
        # which would strip every comment and reformat the user's config.
        updated =
          if config_yaml.key?('inherit_from') && raw.match?(/^inherit_from:[ \t]*$/)
            # Existing block list - prepend our entry as the first item.
            raw.sub(/^inherit_from:[ \t]*$\n/) { "#{Regexp.last_match(0)}  - .yard-lint-todo.yml\n" }
          elsif config_yaml.key?('inherit_from')
            # Existing inline/array form (rare) - fall back to a structured
            # rewrite; comments cannot be preserved in this case.
            config_yaml['inherit_from'] = ['.yard-lint-todo.yml'] + Array(config_yaml['inherit_from'])
            config_yaml.to_yaml
          else
            # No inherit_from yet - prepend a block, preserving the file verbatim.
            "inherit_from:\n  - .yard-lint-todo.yml\n\n#{raw}"
          end

        File.write(@config_path, updated)
      end

      # Create a minimal config file that inherits from todo file
      # @return [void]
      def create_minimal_config
        content = <<~YAML
          # YARD-Lint Configuration
          # See https://github.com/mensfeld/yard-lint for documentation

          inherit_from:
            - .yard-lint-todo.yml
        YAML

        File.write(@config_path, content)
      end

      # Build success result hash with summary message
      # @param violations_by_validator [Hash] hash of validator names to file patterns
      # @param total_offenses [Integer] total number of offenses found
      # @return [Hash] result with :message, :offense_count, :validator_count keys
      def build_success_result(violations_by_validator, total_offenses)
        lines = []
        lines << 'Created .yard-lint-todo.yml'
        lines << "Silenced #{total_offenses} offense(s) across #{violations_by_validator.size} validator(s):"

        violations_by_validator.each do |validator_name, file_patterns|
          lines << "  #{validator_name}: #{file_patterns.size} pattern(s)"
        end

        lines << ''
        lines << 'Updated .yard-lint.yml to inherit from .yard-lint-todo.yml' if File.exist?(@config_path)
        lines << ''
        lines << 'Run yard-lint again to confirm - you should see no offenses.'
        lines << 'To fix violations incrementally, remove entries from .yard-lint-todo.yml'

        {
          message: lines.join("\n"),
          offense_count: total_offenses,
          validator_count: violations_by_validator.size
        }
      end
    end
  end
end
