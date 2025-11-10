# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # UndocumentedBooleanMethods validator
        #
        # Ensures that boolean methods (methods ending with `?`) have an explicit
        # `@return [Boolean]` tag. Boolean methods should clearly document that they
        # return true or false values. This validator is enabled by default.
        #
        # @example Bad - Missing @return tag on boolean method
        #   # Checks if the user is active
        #   def active?
        #     @active
        #   end
        #
        # @example Good - Boolean return documented
        #   # Checks if the user is active
        #   # @return [Boolean] true if the user is active
        #   def active?
        #     @active
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Documentation/UndocumentedBooleanMethods:
        #       Enabled: false
        #
        module UndocumentedBooleanMethods
        end
      end
    end
  end
end
