# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # MissingReturn validator
        #
        # Ensures that all methods have an explicit `@return` tag documented.
        # This validator helps maintain consistent API documentation by catching
        # methods that are missing return value documentation. This validator is
        # disabled by default and must be explicitly enabled in configuration.
        #
        # @example Bad - Missing @return tag
        #   # Calculates the total price
        #   def calculate_total
        #     @items.sum(&:price)
        #   end
        #
        # @example Good - Return value documented
        #   # Calculates the total price
        #   # @return [Float] the total price of all items
        #   def calculate_total
        #     @items.sum(&:price)
        #   end
        #
        # ## Configuration
        #
        # This validator is disabled by default. To enable it:
        #
        #     Documentation/MissingReturn:
        #       Enabled: true
        #       Severity: warning
        #       ExcludedMethods:
        #         - initialize
        #         - '/^_/'  # Exclude private methods starting with underscore
        #
        # ### ExcludedMethods
        #
        # Supports three pattern types:
        # - Simple name: 'initialize' - matches all methods with that name
        # - Arity notation: 'initialize/0' - matches only methods with specific parameter count
        # - Regex pattern: '/^_/' - matches methods using regular expressions
        module MissingReturn
        end
      end
    end
  end
end
