# frozen_string_literal: true

module Yard
  module Lint
    # Contracts that validate the configuration structure and values
    module Contracts
      # Base for the configuration contracts with the helpers that build their error messages
      class Base < Contractable::Contract
        # Valid boolean values
        BOOLEAN_VALUES = [true, false].freeze

        class << self
          private

          # Builds an error message out of its lines
          # @param lines [Array<String, nil>] message lines, nil lines are skipped
          # @return [String] multi-line error message
          def message(*lines)
            lines.compact.join("\n")
          end

          # Converts errors of a nested contract into virtual rule errors of the parent contract
          # @param result [Contractable::Result] nested contract validation result
          # @return [Array<Array>] error pairs with the nested error scope as their path
          def nested_errors(result)
            result.errors.map { |scope, error| [[scope], error] }
          end

          # Suggest similar validator names using did_you_mean
          # @param invalid_name [String] invalid validator name
          # @return [String] suggestion line
          def suggest_validator_name(invalid_name)
            checker = DidYouMean::SpellChecker.new(dictionary: ConfigLoader::ALL_VALIDATORS)
            suggestions = checker.correct(invalid_name)

            if suggestions.any?
              "  Did you mean: #{suggestions.first}?"
            else
              '  See https://github.com/mensfeld/yard-lint/wiki/Validators ' \
                'for all available validators'
            end
          end

          # Suggest similar severity values
          # @param invalid_severity [String] invalid severity value
          # @return [String, nil] suggestion line or nil when there is no similar value
          def suggest_similar_severity(invalid_severity)
            checker = DidYouMean::SpellChecker.new(dictionary: Config::VALID_SEVERITIES)
            suggestions = checker.correct(invalid_severity)

            "  Did you mean: #{suggestions.first}?" if suggestions.any?
          end

          # Suggest similar category configuration keys
          # @param invalid_key [String] invalid category key
          # @return [String, nil] suggestion line or nil when there is no similar key
          def suggest_category_key(invalid_key)
            checker = DidYouMean::SpellChecker.new(dictionary: Category::KEYS)
            suggestions = checker.correct(invalid_key)

            "  Did you mean: #{suggestions.first}?" if suggestions.any?
          end
        end
      end
    end
  end
end
