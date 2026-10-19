# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # UndocumentedBooleanMethods validator
        #
        # Ensures that documented boolean methods (methods ending with `?`) have an
        # explicit `@return` tag, at the top level or inside an `@overload`. Boolean
        # methods should clearly document that they return true or false values.
        # YARD adds `@return [Boolean]` to such methods on its own, so this validator
        # reads the tags written in the comment. Methods without any documentation
        # are reported by `Documentation/UndocumentedObjects`. This validator is
        # enabled by default.
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
        # @example Good - Boolean return documented inside @overload
        #   # Checks if the user is active
        #   # @overload active?(strict)
        #   #   @param strict [Boolean] whether to require a confirmed account
        #   #   @return [Boolean] true if the user is active
        #   def active?(strict)
        #     @active
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Documentation/UndocumentedBooleanMethods:
        #       Enabled: false
        module UndocumentedBooleanMethods
        end
      end
    end
  end
end
