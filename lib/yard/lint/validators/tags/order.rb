# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # Order validator
        #
        # Enforces a consistent order for YARD documentation tags. This validator
        # checks that tags appear in a logical sequence (e.g., `@param` before
        # `@return`, `@option` after `@param`). This validator is enabled by default.
        #
        # @example Bad - Tags in wrong order
        #   # @return [String] the result
        #   # @param name [String] the name
        #   def process(name)
        #   end
        #
        # @example Good - Tags in correct order
        #   # @param name [String] the name
        #   # @return [String] the result
        #   def process(name)
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Tags/Order:
        #       Enabled: false
        #
        module Order
        end
      end
    end
  end
end
