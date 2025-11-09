# frozen_string_literal: true

# YARD Lint - comprehensive linter for YARD documentation
module Yard
  module Lint
    # Configuration object for YARD Lint
    class Config
      attr_reader :raw_config, :validators

      # Default YAML config file name
      DEFAULT_CONFIG_FILE = '.yard-lint.yml'

      # Valid severity levels for fail_on_severity
      VALID_SEVERITIES = %w[error warning convention never].freeze

      # Metadata keys to skip when merging validator configs
      METADATA_KEYS = %w[Description StyleGuide VersionAdded VersionChanged].freeze

      # @param raw_config [Hash] raw configuration hash (new hierarchical format)
      def initialize(raw_config = {})
        @raw_config = raw_config
        @validators = build_validators_config

        yield self if block_given?
      end

      class << self
        # Load configuration from a YAML file
        # @param path [String] path to YAML config file
        # @return [Yard::Lint::Config] configuration object
        # @raise [Yard::Lint::Errors::ConfigFileNotFoundError] if config file doesn't exist
        def from_file(path)
          unless File.exist?(path)
            raise Errors::ConfigFileNotFoundError, "Config file not found: #{path}"
          end

          # Load with inheritance support
          merged_yaml = ConfigLoader.load(path)

          new(merged_yaml)
        end

        # Search for and load config file from current directory upwards
        # @param start_path [String] directory to start searching from (default: current dir)
        # @return [Yard::Lint::Config, nil] config if found, nil otherwise
        def load(start_path: Dir.pwd)
          config_path = find_config_file(start_path)
          config_path ? from_file(config_path) : nil
        end

        # Find config file by searching upwards from start_path
        # @param start_path [String] directory to start searching from
        # @return [String, nil] path to config file if found
        def find_config_file(start_path)
          current = File.expand_path(start_path)
          root = File.expand_path('/')

          loop do
            config_path = File.join(current, DEFAULT_CONFIG_FILE)
            return config_path if File.exist?(config_path)

            break if current == root

            current = File.dirname(current)
          end

          nil
        end
      end

      # YARD command-line options
      # @return [Array<String>] YARD options
      def options
        all_validators['YardOptions'] || []
      end

      # Get YARD options for a specific validator
      # Falls back to global options if validator doesn't specify its own
      # @param validator_name [String] full validator name
      # @return [Array<String>] YARD options for this validator
      def validator_yard_options(validator_name)
        validator_config = validators[validator_name] || {}
        validator_config['YardOptions'] || options
      end

      # Global file exclusion patterns
      # @return [Array<String>] exclusion patterns
      def exclude
        all_validators['Exclude'] || default_exclusions
      end

      # Default exclusion patterns for typical Ruby/Rails projects
      # @return [Array<String>] default exclusion patterns
      def default_exclusions
        [
          # Version control
          '\.git',
          # Dependencies
          'vendor/**/*',
          'node_modules/**/*',
          # Test directories
          'spec/**/*',
          'test/**/*',
          'features/**/*',
          # Temporary and cache directories
          'tmp/**/*',
          'log/**/*',
          'coverage/**/*',
          '.bundle/**/*',
          # Rails-specific
          'db/schema.rb',
          'db/migrate/**/*',
          'public/assets/**/*',
          'public/packs/**/*',
          'public/system/**/*',
          # Build artifacts
          'pkg/**/*',
          'doc/**/*',
          '.yardoc/**/*',
          # Configuration that doesn't need docs
          'config/initializers/**/*',
          'config/environments/**/*'
        ]
      end

      # Minimum severity level to fail on
      # @return [String] severity level (error, warning, convention, never)
      def fail_on_severity
        all_validators['FailOnSeverity'] || 'warning'
      end

      # Check if a validator is enabled
      # @param validator_name [String] full validator name (e.g., 'Tags/Order')
      # @return [Boolean] true if validator is enabled
      def validator_enabled?(validator_name)
        validator_config = validators[validator_name] || {}
        validator_config['Enabled'] != false # Default to true
      end

      # Get validator severity
      # @param validator_name [String] full validator name
      # @return [String] severity level for this validator
      def validator_severity(validator_name)
        validator_config = validators[validator_name] || {}
        validator_config['Severity'] || 'warning'
      end

      # Get validator-specific exclude patterns
      # @param validator_name [String] full validator name
      # @return [Array<String>] exclusion patterns for this validator
      def validator_exclude(validator_name)
        validator_config = validators[validator_name] || {}
        validator_config['Exclude'] || []
      end

      # Combined global and per-validator exclusions
      # Returns all exclusion patterns that apply to this validator
      # @param validator_name [String] full validator name
      # @return [Array<String>] combined exclusion patterns (global + per-validator)
      def validator_all_excludes(validator_name)
        exclude + validator_exclude(validator_name)
      end

      # Get validator-specific configuration value
      # @param validator_name [String] full validator name
      # @param key [String] configuration key
      # @return [Object, nil] configuration value
      def validator_config(validator_name, key)
        validators.dig(validator_name, key)
      end

      # Setter methods for programmatic configuration

      # Set YARD options
      # @param value [Array<String>] YARD options
      def options=(value)
        @raw_config['AllValidators'] ||= {}
        @raw_config['AllValidators']['YardOptions'] = value
      end

      # Set global exclude patterns
      # @param value [Array<String>] exclusion patterns
      def exclude=(value)
        @raw_config['AllValidators'] ||= {}
        @raw_config['AllValidators']['Exclude'] = value
      end

      # Set fail on severity level
      # @param value [String] severity level
      def fail_on_severity=(value)
        @raw_config['AllValidators'] ||= {}
        @raw_config['AllValidators']['FailOnSeverity'] = value
      end

      # Allow hash-like access for convenience
      # @param key [Symbol, String] attribute name to access
      # @return [Object, nil] attribute value or nil if not found
      def [](key)
        respond_to?(key) ? send(key) : nil
      end

      private

      # Generic helper to set validator configuration
      # @param validator_name [String] full validator name (e.g., 'Tags/Order')
      # @param key [String] configuration key
      # @param value [Object] configuration value
      def set_validator_config(validator_name, key, value)
        @raw_config[validator_name] ||= {}
        @raw_config[validator_name][key] = value
        @validators = build_validators_config
      end

      # Generic helper to get validator configuration with default fallback
      # @param validator_name [String] full validator name
      # @param key [String] configuration key
      # @return [Object, nil] configuration value or default
      def get_validator_config_with_default(validator_name, key)
        validator_config(validator_name, key) || begin
          validator_cfg = ConfigLoader.validator_config(validator_name)
          validator_cfg&.defaults&.dig(key)
        end
      end

      # Get AllValidators section
      # @return [Hash] AllValidators configuration
      def all_validators
        @raw_config['AllValidators'] || {}
      end

      # Build validators configuration from raw config
      # @return [Hash] validators configuration
      def build_validators_config
        config = {}

        # Start with defaults for all validators
        ConfigLoader::ALL_VALIDATORS.each do |validator_name|
          config[validator_name] = build_default_validator_config(validator_name)
        end

        # Apply validator-specific overrides
        @raw_config.each do |key, value|
          next unless key.include?('/') # Validator-specific config
          next unless ConfigLoader::ALL_VALIDATORS.include?(key)

          config[key] = merge_validator_config(config[key], value) if value.is_a?(Hash)
        end

        config
      end

      # Build default configuration for a validator
      # @param validator_name [String] full validator name
      # @return [Hash] default configuration
      def build_default_validator_config(validator_name)
        # Get defaults from validator config
        validator_cfg = ConfigLoader.validator_config(validator_name)
        defaults = validator_cfg&.defaults || {}
        base = ConfigLoader::DEFAULT_VALIDATOR_CONFIG.dup

        # Merge validator-specific defaults with base config
        base.merge(defaults)
      end

      # Merge validator configuration
      # @param base [Hash] base configuration
      # @param override [Hash] overriding configuration
      # @return [Hash] merged configuration
      def merge_validator_config(base, override)
        result = base.dup

        override.each do |key, value|
          # Skip metadata keys
          next if METADATA_KEYS.include?(key)

          result[key] = if value.is_a?(Array) && result[key].is_a?(Array)
                          value # Array replacement
                        elsif value.is_a?(Hash) && result[key].is_a?(Hash)
                          result[key].merge(value)
                        else
                          value
                        end
        end

        result
      end
    end
  end
end
