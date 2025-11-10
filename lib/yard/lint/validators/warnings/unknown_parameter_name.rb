# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Validators for checking YARD warnings
      module Warnings
        # UnknownParameterName validator
        #
        # Detects `@param` tags that document parameters which don't exist in the
        # method signature. This often occurs after refactoring when parameter names
        # change but documentation isn't updated. This validator is enabled by default.
        #
        # @example Bad - @param documents non-existent parameter
        #   # @param old_name [String] this parameter doesn't exist anymore
        #   def process(new_name)
        #   end
        #
        # @example Good - @param matches actual parameters
        #   # @param new_name [String] the name to process
        #   def process(new_name)
        #   end
        #
        # @example Configuration - Disable this validator
        #   Warnings/UnknownParameterName:
        #     Enabled: false
        #
        module UnknownParameterName
        end
      end
    end
  end
end
