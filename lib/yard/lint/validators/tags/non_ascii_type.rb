# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # NonAsciiType validator
        #
        # Detects non-ASCII characters in YARD type specifications. Ruby type names
        # must be valid Ruby identifiers which only support ASCII characters. Non-ASCII
        # characters in type specifications are usually the result of copy-paste errors
        # from word processors that use smart typography (e.g., `…` instead of `...`).
        #
        # This validator is enabled by default.
        #
        # @example Bad - Non-ASCII characters in type specification
        #   # @param flags [Symbol, …] variadic flags
        #   # @return [String→Integer] transformation result
        #   def process(flags)
        #   end
        #
        # @example Good - Valid ASCII type syntax
        #   # @param flags [Symbol] variadic flags
        #   # @return [Hash{String => Integer}] transformation result
        #   def process(flags)
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Tags/NonAsciiType:
        #       Enabled: false
        module NonAsciiType
        end
      end
    end
  end
end
