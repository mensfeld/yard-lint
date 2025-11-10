# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Validators for checking YARD warnings
      module Warnings
        # UnknownTag validator
        #
        # Detects usage of unrecognized YARD tags in documentation. This validator
        # checks against YARD's standard tag set and flags any tags that YARD
        # doesn't recognize, which could indicate typos or unsupported tags.
        # This validator is enabled by default.
        #
        # @example Bad - Misspelled or non-existent tags
        #   # @paramm name [String] typo in param tag
        #   # @returns [String] should be @return not @returns
        #   def process(name)
        #   end
        #
        # @example Good - Standard YARD tags
        #   # @param name [String] the name
        #   # @return [String] the result
        #   def process(name)
        #   end
        #
        # @example Configuration - Disable this validator
        #   Warnings/UnknownTag:
        #     Enabled: false
        #
        module UnknownTag
        end
      end
    end
  end
end
