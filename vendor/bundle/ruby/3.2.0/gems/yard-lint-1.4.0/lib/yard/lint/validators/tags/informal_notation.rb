# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # InformalNotation validator
        #
        # Detects informal notation patterns in YARD documentation comments
        # and suggests proper YARD tags. For example, "Note:" should use @note,
        # "TODO:" should use @todo, etc.
        #
        # ## Configuration
        #
        # To customize which patterns are detected:
        #
        # ```yaml
        # Tags/InformalNotation:
        #   Enabled: true
        #   CaseSensitive: false
        #   RequireStartOfLine: true
        #   Patterns:
        #     Note: '@note'
        #     TODO: '@todo'
        # ```
        #
        # @example Good - Using proper YARD tags
        #   # Calculate the sum of values
        #   # @note This method is slow for large arrays
        #   # @todo Optimize for performance
        #   def sum(values)
        #   end
        #
        # @example Bad - Using informal notation
        #   # Calculate the sum of values
        #   # Note: This method is slow for large arrays
        #   # TODO: Optimize for performance
        #   def sum(values)
        #   end
        module InformalNotation
        end
      end
    end
  end
end
