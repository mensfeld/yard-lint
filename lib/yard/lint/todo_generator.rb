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
        # @return [Hash] result with :message, :offense_count, :validator_count
        def generate(path:, config:, force: false, exclude_limit: DEFAULT_EXCLUDE_LIMIT)
          new(path: path, config: config, force: force, exclude_limit: exclude_limit).generate
        end
      end

      # Initialize a new TodoGenerator instance
      # @param path [String] directory or file path containing Ruby files to analyze
      # @param config [Config] yard-lint configuration object
      # @param force [Boolean] whether to overwrite existing todo file
      # @param exclude_limit [Integer] minimum files before grouping into patterns
      def initialize(path:, config:, force:, exclude_limit:)
        @path = path
        @config = config
        @force = force
        @exclude_limit = exclude_limit
        @todo_path = File.join(Dir.pwd, '.yard-lint-todo.yml')
        @config_path = File.join(Dir.pwd, Config::DEFAULT_CONFIG_FILE)
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

      private

      # Validate that the todo file doesn't already exist
      # @raise [Errors::TodoFileExistsError] if todo file exists and force is false
      # @return [void]
      def validate_todo_file_not_exists!
        return unless File.exist?(@todo_path)

        raise Errors::TodoFileExistsError,
          '.yard-lint-todo.yml already exists. Use --regenerate-todo to overwrite.'
      end

      # Run linting and collect violations per validator
      # @return [Hash] hash with :violations_by_validator and :total_offenses keys
      def run_linting
        # Run each validator individually to track violations per validator
        # This is more reliable than trying to infer validator from offense name
        files = Yard::Lint.send(:expand_path, @path, @config)
        runner = Runner.new(files, @config)

        # Run validators and collect raw results
        raw_results = runner.send(:run_validators)
        result_builder = ResultBuilder.new(@config)

        violations_by_validator = {}
        total_offenses = 0

        # Process each validator's results
        ConfigLoader::ALL_VALIDATORS.each do |validator_name|
          next unless @config.validator_enabled?(validator_name)

          validator_result = result_builder.build(validator_name, raw_results)
          next unless validator_result && validator_result.offenses.any?

          # Extract file paths from offenses
          file_paths = validator_result.offenses.map do |offense|
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

      # Convert absolute path to relative path from current directory
      # @param path [String] absolute or relative file path
      # @return [String] relative path from current directory
      def make_relative_path(path)
        pwd = Dir.pwd
        path.start_with?(pwd) ? path.sub("#{pwd}/", '') : path
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
        config_yaml = YAML.load_file(@config_path) || {}
        inherit_from = Array(config_yaml['inherit_from'] || [])

        # Add todo file to inherit_from if not already present
        unless inherit_from.include?('.yard-lint-todo.yml')
          inherit_from.unshift('.yard-lint-todo.yml')
          config_yaml['inherit_from'] = inherit_from

          # Write updated config
          File.write(@config_path, config_yaml.to_yaml)
        end
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
