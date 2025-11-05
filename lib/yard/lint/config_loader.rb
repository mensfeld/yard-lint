# frozen_string_literal: true

module Yard
  module Lint
    # Handles loading and merging of configuration files with inheritance support
    class ConfigLoader
      # Inheritance keys to skip when merging configs
      INHERITANCE_KEYS = %w[inherit_from inherit_gem].freeze

      class << self
        # Get the validator namespace module for a given validator name
        # @param validator_name [String] validator name (e.g., 'Tags/Order')
        # @return [Module, nil] validator namespace module or nil if doesn't exist
        def validator_module(validator_name)
          department, name = validator_name.split('/')
          module_path = "Validators::#{department}::#{name}"

          module_path.split('::').reduce(Yard::Lint) do |mod, const_name|
            return nil unless mod.const_defined?(const_name)

            mod.const_get(const_name)
          end
        end

        # Get the validator config for a given validator name
        # Dynamically resolves the config class based on the validator name
        # @param validator_name [String] validator name (e.g., 'Tags/Order')
        # @return [Class, nil] validator config class or nil if doesn't exist
        def validator_config(validator_name)
          namespace = validator_module(validator_name)
          return nil unless namespace

          # Return the Config class from within the validator namespace
          namespace.const_defined?(:Config) ? namespace.const_get(:Config) : nil
        end

        # Auto-discover validators from the codebase
        # Scans the validators directory and loads all validator modules that have
        # an .id method and .defaults method (indicating they're valid validators)
        # @return [Hash<String, Array<String>>] hash of department names to validator names
        def discover_validators
          departments = Hash.new { |h, k| h[k] = [] }

          validators_path = File.join(__dir__, 'validators')

          # Find all validator module files (e.g., validators/tags/order.rb)
          Dir.glob(File.join(validators_path, '*', '*.rb')).each do |file_path|
            # Require the validator module file to ensure it's loaded
            require file_path

            # Extract department and validator name from path
            # e.g., .../validators/tags/order.rb -> ['tags', 'order']
            relative_path = file_path.sub("#{validators_path}/", '')
            parts = relative_path.sub('.rb', '').split('/')
            department_dir = parts[0]
            validator_dir = parts[1]

            # Convert to proper casing:
            # 'tags' -> 'Tags', 'undocumented_objects' -> 'UndocumentedObjects'
            department = department_dir.split('_').map(&:capitalize).join
            validator = validator_dir.split('_').map(&:capitalize).join

            # Construct the validator name
            validator_name = "#{department}/#{validator}"

            # Verify it's a valid validator by checking if it has a Config class
            cfg = validator_config(validator_name)
            # Every validator must have a Config with id and defaults
            departments[department] << validator_name if cfg && cfg.id && cfg.defaults
          end

          # Sort for consistent ordering
          departments.transform_values(&:sort).sort.to_h
        end

        # Load configuration from file with inheritance support
        # @param path [String] path to configuration file
        # @return [Hash] merged configuration hash
        def load(path)
          new(path).load
        end
      end

      # Validator departments and their validators
      # Auto-discovered from codebase structure
      DEPARTMENTS = discover_validators.freeze

      # All validator names (derived from departments)
      ALL_VALIDATORS = DEPARTMENTS.values.flatten.freeze

      # Default configuration for each validator
      DEFAULT_VALIDATOR_CONFIG = {
        'Enabled' => true,
        'Severity' => nil, # Will use validator's default or department fallback
        'Exclude' => []
      }.freeze

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
        if @loaded_files.include?(path)
          raise Errors::CircularDependencyError, "Circular dependency detected: #{path}"
        end

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
          next if INHERITANCE_KEYS.include?(key)

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
