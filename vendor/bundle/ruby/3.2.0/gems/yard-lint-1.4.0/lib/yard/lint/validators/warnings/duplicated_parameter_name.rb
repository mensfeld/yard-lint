# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Validators for checking YARD warnings
      module Warnings
        # DuplicatedParameterName validator
        #
        # Detects duplicate `@param` tags for the same parameter name. If a parameter
        # is documented multiple times, it's unclear which documentation is correct
        # and can confuse both readers and YARD's parser. This validator is enabled
        # by default.
        #
        # @example Bad - Duplicate @param tags
        #   # @param name [String] the name
        #   # @param name [Symbol] oops, documented again
        #   def process(name)
        #   end
        #
        # @example Good - Each parameter documented once
        #   # @param name [String] the name
        #   # @param age [Integer] the age
        #   def process(name, age)
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Warnings/DuplicatedParameterName:
        #       Enabled: false
        #
        module DuplicatedParameterName
        end
      end
    end
  end
end
