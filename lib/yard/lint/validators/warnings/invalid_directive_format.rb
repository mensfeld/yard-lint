# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Validators for checking YARD warnings
      module Warnings
        # InvalidDirectiveFormat validator
        #
        # Detects malformed YARD directive syntax. Directives have specific format
        # requirements (like `@!attribute [r] name` for read-only attributes), and
        # this validator ensures those requirements are met. This validator is
        # enabled by default.
        #
        # @example Bad - Malformed directive syntax
        #   # @!attribute name missing brackets
        #   # @!method [r] foo wrong format for method
        #   class User
        #   end
        #
        # @example Good - Correctly formatted directives
        #   # @!attribute [r] name
        #   # @!method foo(bar)
        #   class User
        #   end
        #
        # @example Configuration - Disable this validator
        #   Warnings/InvalidDirectiveFormat:
        #     Enabled: false
        #
        module InvalidDirectiveFormat
        end
      end
    end
  end
end
