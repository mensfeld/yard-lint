# frozen_string_literal: true

module Yard
  module Lint
    module Contracts
      # Validates the command line options parsed by `bin/yard-lint`
      class CliOptions < Base
        # Valid output formats
        VALID_FORMATS = %w[text json quickfix sarif].freeze

        class << self
          private

          # Builds the unknown validators message with "did you mean" suggestions, the full list
          # of available validators and a pointer to --explain
          # @param names [Array<String>] unknown validator names
          # @return [String] multi-line error message
          def unknown_validators(names)
            names_lines = names.map do |name|
              suggestion = closest_validator_name(name)
              suggestion ? "  #{name} (did you mean: #{suggestion}?)" : "  #{name}"
            end

            message(
              'Unknown validator(s):',
              *names_lines,
              '',
              'Available validators:',
              *ConfigLoader::ALL_VALIDATORS.map { |validator| "  #{validator}" },
              '',
              'Run `yard-lint --explain VALIDATOR` to see what a validator checks.'
            )
          end
        end

        optional(:format) do |format|
          VALID_FORMATS.include?(format) ||
            "Unknown format '#{format}'. Valid formats: #{VALID_FORMATS.join(', ')}"
        end

        optional(:min_coverage) do |min_cov|
          min_cov.between?(0, 100) ||
            message("Invalid --min-coverage: '#{min_cov}'", '  Must be a number between 0 and 100')
        end

        optional(:only) do |names|
          unknown = names - ConfigLoader::ALL_VALIDATORS
          unknown.empty? || unknown_validators(unknown)
        end

        optional(:explain) do |name|
          ConfigLoader::ALL_VALIDATORS.include?(name) || unknown_validators([name])
        end
      end
    end
  end
end
