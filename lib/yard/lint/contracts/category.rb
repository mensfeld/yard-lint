# frozen_string_literal: true

module Yard
  module Lint
    module Contracts
      # Validates a category-level configuration (e.g. `Documentation: { Severity: ... }`)
      class Category < Base
        # Keys that are valid in a category-level configuration
        KEYS = %w[Enabled Exclude Severity].freeze

        # @return [String] category name
        attr_reader :name

        class << self
          private

          # Suggest similar category configuration keys
          # @param invalid_key [String] invalid category key
          # @return [String, nil] suggestion line or nil when there is no similar key
          def suggest_category_key(invalid_key)
            checker = DidYouMean::SpellChecker.new(dictionary: KEYS)
            suggestions = checker.correct(invalid_key)

            "  Did you mean: #{suggestions.first}?" if suggestions.any?
          end
        end

        # @param name [String] category name used in error messages
        def initialize(name)
          super()
          @name = name
        end

        optional('Enabled') do |enabled, _data, _errors, contract|
          BOOLEAN_VALUES.include?(enabled) ||
            message(
              "Invalid Enabled value for category #{contract.name}: '#{enabled}'",
              '  Must be true or false'
            )
        end

        optional('Exclude') do |exclude, _data, _errors, contract|
          !exclude || exclude.is_a?(Array) ||
            "Invalid Exclude for category #{contract.name}: must be an array, got #{exclude.class}"
        end

        optional('Severity') do |severity, _data, _errors, contract|
          !severity || Lint::Config::VALID_SEVERITIES.include?(severity.to_s) ||
            message(
              "Invalid Severity for category #{contract.name}: '#{severity}'",
              "  Valid values: #{Lint::Config::VALID_SEVERITIES.join(', ')}",
              suggest_similar_severity(severity.to_s)
            )
        end

        virtual do |data, _errors, contract|
          (data.keys - KEYS).map do |key|
            [
              [key],
              message(
                "Unknown configuration key for category #{contract.name}: '#{key}'",
                "  Valid keys: #{KEYS.join(', ')}",
                suggest_category_key(key.to_s)
              )
            ]
          end
        end
      end
    end
  end
end
