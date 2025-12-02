# frozen_string_literal: true

module Yard
  module Lint
    # Updates existing .yard-lint.yml configuration files
    # Adds new validators, removes obsolete ones, preserves user settings
    class ConfigUpdater
      # Path to templates directory
      TEMPLATES_DIR = File.expand_path('templates', __dir__)

      # Category order for output
      CATEGORY_ORDER = %w[Documentation Tags Warnings Semantic].freeze

      # Category comments for output
      CATEGORY_COMMENTS = {
        'Documentation' => '# Documentation validators',
        'Tags' => '# Tags validators',
        'Warnings' => '# Warnings validators - catches YARD parser errors',
        'Semantic' => '# Semantic validators'
      }.freeze

      class << self
        # Update an existing config file
        # @param path [String] path to config file (default: .yard-lint.yml in current dir)
        # @param strict [Boolean] use strict template as base for new validators
        # @return [Hash] result hash with :added, :removed, :preserved arrays
        def update(path: nil, strict: false)
          new(path: path, strict: strict).update
        end
      end

      # @param path [String, nil] path to config file
      # @param strict [Boolean] use strict template
      def initialize(path: nil, strict: false)
        @path = path || File.join(Dir.pwd, Config::DEFAULT_CONFIG_FILE)
        @strict = strict
      end

      # Perform the config update
      # @return [Hash] result with :added, :removed, :preserved arrays
      def update
        validate_file_exists!

        existing_config = load_existing_config
        template_config = load_template_config

        result = merge_configs(existing_config, template_config)

        write_updated_config(result[:config])

        {
          added: result[:added],
          removed: result[:removed],
          preserved: result[:preserved]
        }
      end

      private

      # Validate that the config file exists
      # @raise [Errors::ConfigFileNotFoundError] if file doesn't exist
      def validate_file_exists!
        return if File.exist?(@path)

        raise Errors::ConfigFileNotFoundError,
          "Config file not found: #{@path}. Use --init to create one."
      end

      # Load the existing user config
      # @return [Hash] parsed YAML config
      def load_existing_config
        YAML.load_file(@path) || {}
      end

      # Load the template config
      # @return [Hash] parsed template YAML
      def load_template_config
        template_name = @strict ? 'strict_config.yml' : 'default_config.yml'
        template_path = File.join(TEMPLATES_DIR, template_name)
        YAML.load_file(template_path)
      end

      # Merge existing config with template to add new and remove obsolete validators
      # @param existing [Hash] existing user config
      # @param template [Hash] template config
      # @return [Hash] result with :config, :added, :removed, :preserved
      def merge_configs(existing, template)
        current_validators = ConfigLoader::ALL_VALIDATORS
        existing_validators = extract_validator_keys(existing)

        # Calculate changes
        added = (current_validators - existing_validators).sort
        removed = (existing_validators - current_validators).sort
        preserved = (existing_validators & current_validators).sort

        # Build merged config
        merged = {}

        # Copy AllValidators from existing, falling back to template
        merged['AllValidators'] = existing['AllValidators'] || template['AllValidators']

        # Process validators in template order (which has proper category grouping)
        template.each_key do |key|
          next if key == 'AllValidators'
          next unless key.include?('/')
          next unless current_validators.include?(key)

          merged[key] = if existing.key?(key)
                          # Preserve existing user config, but merge with template defaults
                          merge_validator_config(template[key], existing[key])
                        else
                          # New validator - use template defaults
                          template[key].dup
                        end
        end

        {
          config: merged,
          added: added,
          removed: removed,
          preserved: preserved
        }
      end

      # Extract validator keys (keys containing '/') from config
      # @param config [Hash] configuration hash
      # @return [Array<String>] validator keys
      def extract_validator_keys(config)
        config.keys.select { |k| k.include?('/') }
      end

      # Merge template defaults with user config
      # User config takes precedence
      # @param template_config [Hash] template validator config
      # @param user_config [Hash] user validator config
      # @return [Hash] merged config
      def merge_validator_config(template_config, user_config)
        result = template_config.dup
        user_config.each do |key, value|
          result[key] = value
        end
        result
      end

      # Write the updated config to file
      # @param config [Hash] merged config to write
      def write_updated_config(config)
        content = generate_yaml_content(config)
        File.write(@path, content)
      end

      # Generate YAML content with proper formatting and section comments
      # @param config [Hash] merged configuration with AllValidators and validator sections
      # @return [String] formatted YAML content
      def generate_yaml_content(config)
        lines = []
        lines << '# YARD-Lint Configuration'
        lines << '# See https://github.com/mensfeld/yard-lint for documentation'
        lines << ''

        # Write AllValidators section
        if config['AllValidators']
          lines << '# Global settings for all validators'
          lines << 'AllValidators:'
          lines.concat(yaml_hash_lines(config['AllValidators'], indent: 2))
          lines << ''
        end

        # Group validators by category
        categories = group_by_category(config)

        # Write each category in order
        CATEGORY_ORDER.each do |category|
          validators = categories[category]
          next unless validators&.any?

          lines << CATEGORY_COMMENTS[category] if CATEGORY_COMMENTS[category]

          validators.each do |validator_name, validator_config|
            lines << "#{validator_name}:"
            lines.concat(yaml_hash_lines(validator_config, indent: 2))
            lines << ''
          end
        end

        lines.join("\n")
      end

      # Group validators by their category
      # @param config [Hash] config with validator keys
      # @return [Hash{String => Hash}] validators grouped by category
      def group_by_category(config)
        categories = Hash.new { |h, k| h[k] = {} }

        config.each do |key, value|
          next unless key.include?('/')

          category = key.split('/').first
          categories[category][key] = value
        end

        categories
      end

      # Convert a hash to indented YAML lines
      # @param hash [Hash] validator or AllValidators configuration to format as YAML
      # @param indent [Integer] number of spaces to indent
      # @return [Array<String>] indented YAML lines
      def yaml_hash_lines(hash, indent:)
        yaml_str = hash.to_yaml
        # Remove the "---\n" header and convert to indented lines
        yaml_str.lines[1..].map do |line|
          if line.strip.empty?
            ''
          else
            "#{' ' * indent}#{line.rstrip}"
          end
        end
      end
    end
  end
end
