# frozen_string_literal: true

module Yard
  module Lint
    module Contracts
      # Validates the whole configuration: root keys, AllValidators, categories and validators
      class Root < Base
        # Valid category names (from ConfigUpdater::CATEGORY_ORDER)
        VALID_CATEGORIES = %w[Documentation Tags Warnings Semantic].freeze

        # Keys that are valid at the root level but are not validators
        SPECIAL_KEYS = %w[
          AllValidators
          inherit_from
          inherit_gem
        ].freeze

        # Validator names must contain a '/' (category/name format)
        virtual do |data|
          data.keys.filter_map do |key|
            next if SPECIAL_KEYS.include?(key)
            next if VALID_CATEGORIES.include?(key)
            next if key.include?('/')

            [[key], message("Unknown validator: '#{key}'", suggest_validator_name(key))]
          end
        end

        optional('AllValidators') do |all_validators|
          !all_validators || all_validators.is_a?(Hash) ||
            "Invalid AllValidators: must be a Hash, got #{all_validators.class}"
        end

        # Only specific known settings are validated, unknown keys pass through
        # This allows users to put custom data in AllValidators
        nested('AllValidators') do
          optional('FailOnSeverity') do |fail_on|
            !fail_on || Config::VALID_SEVERITIES.include?(fail_on.to_s) ||
              message("Invalid FailOnSeverity: '#{fail_on}'", "  Valid values: #{Config::VALID_SEVERITIES.join(', ')}")
          end

          optional('MinCoverage') do |min_cov|
            !min_cov || (min_cov.is_a?(Numeric) && !(min_cov < 0 || min_cov > 100)) ||
              message("Invalid MinCoverage: '#{min_cov}'", '  Must be a number between 0 and 100')
          end

          optional('Exclude') do |exclude|
            !exclude || exclude.is_a?(Array) ||
              "Invalid Exclude in AllValidators: must be an array, got #{exclude.class}"
          end

          optional('YardOptions') do |yard_options|
            !yard_options || yard_options.is_a?(Array) ||
              "Invalid YardOptions in AllValidators: must be an array, got #{yard_options.class}"
          end
        end

        virtual do |data|
          data.flat_map do |key, value|
            next [] unless VALID_CATEGORIES.include?(key)
            next [] unless value.is_a?(Hash)

            nested_errors(Category.new(key).call(value, scope: [key]))
          end
        end

        virtual do |data|
          data.flat_map do |key, value|
            next [] unless key.include?('/')

            unless value.is_a?(Hash)
              next [[[key], "Invalid configuration for validator '#{key}': expected a Hash, got #{value.class}"]]
            end

            nested_errors(Validator.new(key).call(value, scope: [key]))
          end
        end
      end
    end
  end
end
