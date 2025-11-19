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
        # Provides intelligent "did you mean" suggestions for common typos using
        # Ruby's did_you_mean gem with Levenshtein distance fallback.
        #
        # @example Bad - Misspelled or non-existent tags
        #   # @param name [String] typo in param tag
        #   # @returns [String] should be @return not @returns
        #   # @raises [Error] should be @raise not @raises
        #   def process(name)
        #   end
        #
        # @example Good - Standard YARD tags
        #   # @param name [String] the name
        #   # @return [String] the result
        #   # @raise [Error] the error
        #   def process(name)
        #   end
        #
        # @example Output with suggestions
        #   lib/foo.rb:10: [error] Unknown tag @returns (did you mean '@return'?)
        #   lib/foo.rb:11: [error] Unknown tag @raises (did you mean '@raise'?)
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Warnings/UnknownTag:
        #       Enabled: false
        #
        module UnknownTag
        end
      end
    end
  end
end
