# frozen_string_literal: true

require 'yaml'
require 'net/http'
require 'uri'

module Yard
  module Lint
    # Handles loading and merging of configuration files with inheritance support
    class ConfigLoader
      # Validator departments and their validators
      # Note: This lists actual configurable validators. Some validators (like Warnings/Stats)
      # may use multiple internal parsers, but those are implementation details, not separate validators.
      DEPARTMENTS = {
        'Documentation' => %w[
          Documentation/UndocumentedObjects
          Documentation/UndocumentedMethodArguments
          Documentation/UndocumentedBooleanMethods
        ],
        'Tags' => %w[
          Tags/InvalidTypes
          Tags/Order
          Tags/ApiTags
          Tags/OptionTags
        ],
        'Warnings' => %w[
          Warnings/Stats
        ],
        'Semantic' => %w[
          Semantic/AbstractMethods
        ]
      }.freeze

      # All validator names (derived from departments)
      ALL_VALIDATORS = DEPARTMENTS.values.flatten.freeze

      # Default configuration for each validator
      DEFAULT_VALIDATOR_CONFIG = {
        'Enabled' => true,
        'Severity' => nil, # Will use validator's default or department fallback
        'Exclude' => []
      }.freeze

      class << self
        # Load configuration from file with inheritance support
        # @param path [String] path to configuration file
        # @return [Hash] merged configuration hash
        def load(path)
          new(path).load
        end

        # Get the validator module for a given validator name
        # Dynamically resolves the module based on the validator name
        # @param validator_name [String] validator name (e.g., 'Tags/Order')
        # @return [Module, nil] validator module or nil if no module exists
        def validator_module(validator_name)
          # Convert validator name to module path
          # e.g., 'Tags/Order' => 'Validators::Tags::Order'
          # e.g., 'Warnings/Stats' => 'Validators::Warnings::Stats'
          # e.g., 'Documentation/UndocumentedObjects' => 'Validators::Documentation::UndocumentedObjects'
          department, name = validator_name.split('/')
          module_path = "Validators::#{department}::#{name}"

          # Dynamically resolve the module
          module_path.split('::').reduce(Yard::Lint) do |mod, const_name|
            mod.const_get(const_name)
          end
        rescue NameError
          nil
        end
      end

      # @param path [String] path to configuration file
      def initialize(path)
        @path = path
        @loaded_files = []
      end

      # Load and merge configuration with inheritance
      # @return [Hash] final merged configuration
      def load
        load_file(@path)
      end

      private

      # Load a single configuration file and handle inheritance
      # @param path [String] path to configuration file
      # @return [Hash] configuration hash with inheritance resolved
      # @raise [Yard::Lint::Errors::CircularDependencyError] if circular dependency detected
      def load_file(path)
        # Prevent circular dependencies
        raise Errors::CircularDependencyError, "Circular dependency detected: #{path}" if @loaded_files.include?(path)

        @loaded_files << path

        yaml = YAML.load_file(path) || {}

        # Handle inheritance
        base_config = load_inherited_configs(yaml, File.dirname(path))

        # Merge current config over inherited config
        merge_configs(base_config, yaml)
      end

      # Load all inherited configurations
      # @param yaml [Hash] current configuration hash
      # @param base_dir [String] directory containing the config file
      # @return [Hash] merged inherited configuration
      def load_inherited_configs(yaml, base_dir)
        config = {}

        # Load inherit_from (local files)
        if yaml['inherit_from']
          inherit_from = Array(yaml['inherit_from'])
          inherit_from.each do |file|
            inherited_path = File.expand_path(file, base_dir)
            if File.exist?(inherited_path)
              inherited = load_file(inherited_path)
              config = merge_configs(config, inherited)
            end
          end
        end

        # Load inherit_gem (gem-based configs)
        yaml['inherit_gem']&.each do |gem_name, gem_file|
          inherited = load_gem_config(gem_name, gem_file)
          config = merge_configs(config, inherited) if inherited
        end

        config
      end

      # Load configuration from a gem
      # @param gem_name [String] name of the gem
      # @param gem_file [String] relative path within the gem
      # @return [Hash, nil] configuration hash or nil if not found
      def load_gem_config(gem_name, gem_file)
        gem_spec = Gem::Specification.find_by_name(gem_name)
        config_path = File.join(gem_spec.gem_dir, gem_file)

        return nil unless File.exist?(config_path)

        load_file(config_path)
      rescue Gem::MissingSpecError
        warn "Warning: Gem '#{gem_name}' not found for configuration inheritance"
        nil
      end

      # Merge two configuration hashes
      # @param base [Hash] base configuration
      # @param override [Hash] overriding configuration
      # @return [Hash] merged configuration
      def merge_configs(base, override)
        result = base.dup

        override.each do |key, value|
          # Skip inheritance keys in merged result
          next if %w[inherit_from inherit_gem].include?(key)

          result[key] = if value.is_a?(Hash) && result[key].is_a?(Hash)
                          merge_configs(result[key], value)
                        elsif value.is_a?(Array) && result[key].is_a?(Array)
                          # For arrays, override completely (RuboCop behavior)
                          value
                        else
                          value
                        end
        end

        result
      end
    end
  end
end
