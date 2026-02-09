# frozen_string_literal: true

# YARD Lint - comprehensive linter for YARD documentation
module Yard
  # YARD Lint module providing linting functionality for YARD documentation
  module Lint
    # Validates configuration structure and values to catch typos and invalid settings
    class ConfigValidator
      # Valid category names (from ConfigUpdater::CATEGORY_ORDER)
      VALID_CATEGORIES = %w[Documentation Tags Warnings Semantic].freeze

      # Keys that are valid at the root level but are not validators
      SPECIAL_KEYS = %w[
        AllValidators
        inherit_from
        inherit_gem
      ].freeze

      # Valid boolean values
      BOOLEAN_VALUES = [true, false].freeze

      # @param raw_config [Hash] raw configuration hash to validate
      def initialize(raw_config)
        @raw_config = raw_config
        @errors = []
      end

      # Validate configuration and raise error if invalid
      # @param raw_config [Hash] raw configuration hash to validate
      # @return [void]
      # @raise [Errors::InvalidConfigError] if configuration is invalid
      def self.validate!(raw_config)
        validator = new(raw_config)
        validator.validate!
      end

      # Perform validation
      # @return [void]
      # @raise [Errors::InvalidConfigError] if configuration is invalid
      def validate!
        validate_root_keys!
        validate_global_settings!
        validate_validators!

        return if @errors.empty?

        raise Errors::InvalidConfigError, build_error_message
      end

      private

      # Validate root-level keys in configuration
      def validate_root_keys!
        @raw_config.each_key do |key|
          # Skip special keys
          next if SPECIAL_KEYS.include?(key)

          # Skip category-level configs (e.g., 'Documentation', 'Tags')
          next if VALID_CATEGORIES.include?(key)

          # Validator names must contain a '/' (category/name format)
          next if key.include?('/')

          # If we get here, it's an unknown validator (missing category prefix)
          @errors << "Unknown validator: '#{key}'"
          suggest_validator_name(key)
        end
      end

      # Validate AllValidators section
      def validate_global_settings!
        all_validators = @raw_config['AllValidators']
        return unless all_validators

        unless all_validators.is_a?(Hash)
          @errors << "Invalid AllValidators: must be a Hash, got #{all_validators.class}"
          return
        end

        # Only validate specific known settings, allow unknown keys to pass through
        # This allows users to put custom data in AllValidators

        # Validate FailOnSeverity value
        fail_on = all_validators['FailOnSeverity']
        if fail_on && !Config::VALID_SEVERITIES.include?(fail_on.to_s)
          @errors << "Invalid FailOnSeverity: '#{fail_on}'"
          @errors << "  Valid values: #{Config::VALID_SEVERITIES.join(', ')}"
        end

        # Validate MinCoverage value
        min_cov = all_validators['MinCoverage']
        if min_cov && (!min_cov.is_a?(Numeric) || min_cov < 0 || min_cov > 100)
          @errors << "Invalid MinCoverage: '#{min_cov}'"
          @errors << '  Must be a number between 0 and 100'
        end

        # Validate Exclude is an array
        exclude = all_validators['Exclude']
        if exclude && !exclude.is_a?(Array)
          @errors << "Invalid Exclude in AllValidators: must be an array, got #{exclude.class}"
        end

        # Validate YardOptions is an array
        yard_options = all_validators['YardOptions']
        if yard_options && !yard_options.is_a?(Array)
          @errors << "Invalid YardOptions in AllValidators: must be an array, got #{yard_options.class}"
        end
      end

      # Validate validator-specific configurations
      def validate_validators!
        @raw_config.each do |key, value|
          # Only process validator keys (containing '/')
          next unless key.include?('/')

          unless value.is_a?(Hash)
            @errors << "Invalid configuration for validator '#{key}': expected a Hash, got #{value.class}"
            next
          end

          validate_validator_exists!(key)
          validate_validator_config!(key, value)
        end
      end

      # Check if validator name exists
      # @param validator_name [String] validator name to check
      # @return [void]
      def validate_validator_exists!(validator_name)
        return if ConfigLoader::ALL_VALIDATORS.include?(validator_name)

        @errors << "Unknown validator: '#{validator_name}'"
        suggest_validator_name(validator_name)
      end

      # Validate individual validator configuration
      # @param validator_name [String] validator name
      # @param config [Hash] validator configuration hash
      # @return [void]
      def validate_validator_config!(validator_name, config)
        # Validate Enabled value
        enabled = config['Enabled']
        if enabled && !BOOLEAN_VALUES.include?(enabled)
          @errors << "Invalid Enabled value for #{validator_name}: '#{enabled}'"
          @errors << '  Must be true or false'
        end

        # Validate Severity value
        severity = config['Severity']
        if severity && !Config::VALID_SEVERITIES.include?(severity.to_s)
          @errors << "Invalid Severity for #{validator_name}: '#{severity}'"
          @errors << "  Valid values: #{Config::VALID_SEVERITIES.join(', ')}"
          suggest_similar_severity(severity.to_s)
        end

        # Validate Exclude is an array
        exclude = config['Exclude']
        if exclude && !exclude.is_a?(Array)
          @errors << "Invalid Exclude for #{validator_name}: must be an array, got #{exclude.class}"
        end

        # Validate YardOptions is an array
        yard_options = config['YardOptions']
        if yard_options && !yard_options.is_a?(Array)
          @errors << "Invalid YardOptions for #{validator_name}: must be an array, got #{yard_options.class}"
        end

        # Check for unknown validator-specific keys
        validate_validator_specific_keys!(validator_name, config)
      end

      # Validate validator-specific configuration keys
      # @param validator_name [String] validator name
      # @param config [Hash] validator configuration hash
      # @return [void]
      def validate_validator_specific_keys!(validator_name, config)
        # Skip if validator doesn't exist (already reported)
        return unless ConfigLoader::ALL_VALIDATORS.include?(validator_name)

        validator_config_class = ConfigLoader.validator_config(validator_name)
        return unless validator_config_class

        # Base config keys that are valid for all validators
        base_keys = %w[Enabled Severity Exclude YardOptions]
        valid_keys = validator_config_class.defaults.keys + Config::METADATA_KEYS + base_keys

        config.each_key do |key|
          next if valid_keys.include?(key)

          @errors << "Unknown configuration key for #{validator_name}: '#{key}'"
          @errors << "  Valid keys: #{valid_keys.uniq.sort.join(', ')}"
        end
      end

      # Suggest similar validator names using did_you_mean
      # @param invalid_name [String] invalid validator name
      # @return [void]
      def suggest_validator_name(invalid_name)
        checker = DidYouMean::SpellChecker.new(dictionary: ConfigLoader::ALL_VALIDATORS)
        suggestions = checker.correct(invalid_name)

        if suggestions.any?
          @errors << "  Did you mean: #{suggestions.first}?"
        else
          @errors << '  Run `yard-lint --list-validators` to see all available validators'
        end
      end

      # Suggest similar severity values
      # @param invalid_severity [String] invalid severity value
      # @return [void]
      def suggest_similar_severity(invalid_severity)
        checker = DidYouMean::SpellChecker.new(dictionary: Config::VALID_SEVERITIES)
        suggestions = checker.correct(invalid_severity)

        if suggestions.any?
          @errors << "  Did you mean: #{suggestions.first}?"
        end
      end

      # Build comprehensive error message
      def build_error_message
        header = 'Invalid configuration detected:'
        errors_text = @errors.map { |e| "  #{e}" }.join("\n")

        "#{header}\n#{errors_text}"
      end
    end
  end
end
