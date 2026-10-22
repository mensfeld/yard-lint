# frozen_string_literal: true

module Yard
  module Lint
    module Contracts
      # Validates a single validator configuration (e.g. `Tags/Order: { Enabled: ... }`)
      class Validator < Base
        # Base config keys that are valid for all validators
        BASE_KEYS = %w[Enabled Severity Exclude YardOptions].freeze

        # @return [String] validator name
        attr_reader :name

        # @param name [String] validator name used in error messages
        def initialize(name)
          super()
          @name = name
        end

        virtual do |_data, _errors, contract|
          next if ConfigLoader::ALL_VALIDATORS.include?(contract.name)

          [[[], message("Unknown validator: '#{contract.name}'", suggest_validator_name(contract.name))]]
        end

        optional('Enabled') do |enabled, _data, _errors, contract|
          !enabled || BOOLEAN_VALUES.include?(enabled) ||
            message("Invalid Enabled value for #{contract.name}: '#{enabled}'", '  Must be true or false')
        end

        optional('Severity') do |severity, _data, _errors, contract|
          !severity || Lint::Config::VALID_SEVERITIES.include?(severity.to_s) ||
            message(
              "Invalid Severity for #{contract.name}: '#{severity}'",
              "  Valid values: #{Lint::Config::VALID_SEVERITIES.join(', ')}",
              suggest_similar_severity(severity.to_s)
            )
        end

        optional('Exclude') do |exclude, _data, _errors, contract|
          !exclude || exclude.is_a?(Array) ||
            "Invalid Exclude for #{contract.name}: must be an array, got #{exclude.class}"
        end

        optional('YardOptions') do |yard_options, _data, _errors, contract|
          !yard_options || yard_options.is_a?(Array) ||
            "Invalid YardOptions for #{contract.name}: must be an array, got #{yard_options.class}"
        end

        # Unknown validator-specific keys (an unknown validator is already reported)
        virtual do |data, _errors, contract|
          next unless ConfigLoader::ALL_VALIDATORS.include?(contract.name)

          validator_config_class = ConfigLoader.validator_config(contract.name)
          next unless validator_config_class

          valid_keys = (validator_config_class.defaults.keys + Lint::Config::METADATA_KEYS + BASE_KEYS).uniq.sort

          (data.keys - valid_keys).map do |key|
            [
              [key],
              message(
                "Unknown configuration key for #{contract.name}: '#{key}'",
                "  Valid keys: #{valid_keys.join(', ')}"
              )
            ]
          end
        end
      end
    end
  end
end
