# frozen_string_literal: true

module Yard
  module Lint
    # Contracts that validate the configuration and the command line options
    module Contracts
      # Base for the configuration and command line options contracts with the helpers that
      # build their error messages
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

          # Checks a minimum documentation coverage, shared by MinCoverage and --min-coverage
          # @param value [Object] coverage value to check
          # @return [Boolean] true when the value is a number between 0 and 100
          def valid_coverage?(value)
            value.is_a?(Numeric) && value >= 0 && value <= 100
          end

          # Converts errors of a nested contract into virtual rule errors of the parent contract
          # @param result [Contractable::Result] nested contract validation result
          # @return [Array<Array>] error pairs with the nested error scope as their path
          def nested_errors(result)
            result.errors.map { |scope, error| [[scope], error] }
          end

          # Finds the validator name closest to an invalid one using did_you_mean
          # @param invalid_name [String] invalid validator name
          # @return [String, nil] closest validator name or nil when there is no similar one
          def closest_validator_name(invalid_name)
            DidYouMean::SpellChecker.new(dictionary: ConfigLoader::ALL_VALIDATORS).correct(invalid_name).first
          end

          # Suggest similar validator names using did_you_mean
          # @param invalid_name [String] invalid validator name
          # @return [String] suggestion line
          def suggest_validator_name(invalid_name)
            suggestion = closest_validator_name(invalid_name)

            if suggestion
              "  Did you mean: #{suggestion}?"
            else
              '  See https://github.com/mensfeld/yard-lint/wiki/Validators ' \
                'for all available validators'
            end
          end

          # Suggest similar severity values
          # @param invalid_severity [String] invalid severity value
          # @return [String, nil] suggestion line or nil when there is no similar value
          def suggest_similar_severity(invalid_severity)
            checker = DidYouMean::SpellChecker.new(dictionary: Lint::Config::VALID_SEVERITIES)
            suggestions = checker.correct(invalid_severity)

            "  Did you mean: #{suggestions.first}?" if suggestions.any?
          end
        end
      end
    end
  end
end
