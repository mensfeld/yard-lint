# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Validators for checking YARD warnings
      module Warnings
        # InvalidTagFormat validator
        #
        # Detects malformed YARD tag syntax. This validator checks that tags follow
        # the correct format expected by YARD, such as proper spacing, brackets for
        # types, and required components. This validator is enabled by default.
        #
        # @example Bad - Malformed tag syntax
        #   # @param name[String] missing space before type
        #   # @return [String the result missing closing bracket
        #   def process(name)
        #   end
        #
        # @example Good - Correctly formatted tags
        #   # @param name [String] the name
        #   # @return [String] the result
        #   def process(name)
        #   end
        #
        # @example Configuration - Disable this validator
        #   Warnings/InvalidTagFormat:
        #     Enabled: false
        #
        module InvalidTagFormat
        end
      end
    end
  end
end
