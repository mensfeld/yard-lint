# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # UndocumentedMethodArguments validator
        #
        # Ensures that all method parameters are documented with `@param` tags.
        # This validator checks that every parameter in a method signature has
        # a corresponding `@param` documentation tag. This validator is enabled
        # by default.
        #
        # @example Bad - Missing @param tags
        #   # Does something with data
        #   def process(name, options)
        #   end
        #
        # @example Good - All parameters documented
        #   # Does something with data
        #   # @param name [String] the name to process
        #   # @param options [Hash] configuration options
        #   def process(name, options)
        #   end
        #
        # @example Configuration - Disable this validator
        #   Documentation/UndocumentedMethodArguments:
        #     Enabled: false
        #
        module UndocumentedMethodArguments
        end
      end
    end
  end
end
