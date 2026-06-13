# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # InvalidTypes validator
        #
        # Detects invalid or malformed type annotations in YARD tags. This validator
        # checks that type specifications follow YARD's type syntax rules and that
        # type names are valid. This validator is enabled by default.
        #
        # @example Bad - Invalid type syntax
        #   # @param name [String | Integer] the name (wrong pipe syntax)
        #   # @return [Array[String]] invalid nested syntax
        #   def process(name)
        #   end
        #
        # @example Good - Valid type syntax
        #   # @param name [String, Integer] the name (comma-separated union)
        #   # @return [Array<String>] valid nested syntax
        #   def process(name)
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Tags/InvalidTypes:
        #       Enabled: false
        module InvalidTypes
        end
      end
    end
  end
end
