# frozen_string_literal: true

module Yard
  module Lint
    module Executor
      # Routes captured YARD warnings to appropriate warning validators.
      # Uses the same regex patterns as the existing parsers to ensure consistency.
      class WarningDispatcher
        # Patterns matching the 'general' regexps from each warning validator's parser.
        # These patterns identify which validator should handle each warning.
        PATTERNS = {
          'Warnings/UnknownTag' => /^\[warn\]: Unknown tag.*@.*near line/,
          'Warnings/UnknownParameterName' => /^\[warn\]: @param tag has unknown parameter name/,
          'Warnings/DuplicatedParameterName' => /^\[warn\]: @param tag has duplicate parameter name/,
          'Warnings/UnknownDirective' => /^\[warn\]: Unknown directive.*@!.*near line/,
          'Warnings/InvalidTagFormat' => /^\[warn\]: Invalid tag format/,
          'Warnings/InvalidDirectiveFormat' => /^\[warn\]: Invalid directive format/
        }.freeze

        # Dispatch warnings to appropriate validators
        # @param warnings [Array<String>] raw warning messages from YARD
        # @return [Hash{String => Array<String>}] warnings grouped by validator name
        def dispatch(warnings)
          grouped = Hash.new { |h, k| h[k] = [] }

          warnings.each do |warning|
            # Format the warning as YARD outputs it
            formatted = format_warning(warning)

            PATTERNS.each do |validator_name, pattern|
              if formatted.match?(pattern)
                grouped[validator_name] << formatted
                break
              end
            end
          end

          grouped
        end

        # Format a raw warning to match YARD's stderr output format
        # @param warning [String] raw warning message
        # @return [String] formatted warning
        def format_warning(warning)
          # If the warning already has [warn]: prefix, return as-is
          return warning if warning.start_with?('[warn]:')

          "[warn]: #{warning}"
        end

        # Build result hash for a validator from its dispatched warnings
        # The warnings are put in stdout because the ResultBuilder reads from stdout
        # (in shell mode, YARD outputs warnings to stderr but they get combined)
        # @param warnings [Array<String>] warnings for this validator
        # @return [Hash] result hash with :stdout, :stderr, :exit_code keys
        def format_for_validator(warnings)
          {
            stdout: warnings.join("\n"),
            stderr: '',
            exit_code: 0
          }
        end

        # Check if a validator is a warning validator (handled by dispatcher)
        # @param validator_name [String] full validator name
        # @return [Boolean]
        def warning_validator?(validator_name)
          PATTERNS.key?(validator_name)
        end

        # Get all warning validator names
        # @return [Array<String>]
        def warning_validator_names
          PATTERNS.keys
        end
      end
    end
  end
end
