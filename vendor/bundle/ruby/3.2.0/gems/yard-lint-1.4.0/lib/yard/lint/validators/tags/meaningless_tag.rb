# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # MeaninglessTag validator
        #
        # Prevents `@param` and `@option` tags from being used on classes, modules,
        # or constants, where they make no sense. These tags are only valid on methods.
        # This validator is enabled by default.
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Tags/MeaninglessTag:
        #       Enabled: false
        #
        # @example Bad - @param on a class
        #   # @param name [String] this makes no sense on a class
        #   class User
        #   end
        #
        # @example Bad - @option on a module
        #   # @option config [Boolean] :enabled modules don't have parameters
        #   module Authentication
        #   end
        #
        # @example Good - @param on a method
        #   class User
        #     # @param name [String] the user's name
        #     def initialize(name)
        #       @name = name
        #     end
        #   end
        module MeaninglessTag
        end
      end
    end
  end
end
