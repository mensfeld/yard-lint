# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # TagTypePosition validator
        #
        # Ensures consistent type annotation positioning in YARD documentation tags.
        # By default, it enforces YARD standard style where the type appears after
        # the parameter name (`@param name [Type]`), but you can configure it to
        # enforce `type_first` style if your team prefers that convention.
        # This validator is enabled by default.
        #
        # @example Good - Type after parameter name (YARD standard)
        #   # @param name [String] the user's name
        #   # @param age [Integer] the user's age
        #   # @param options [Hash{Symbol => Object}] configuration options
        #   def create_user(name, age, options = {})
        #   end
        #
        # @example Bad - Type before parameter name (when using default style)
        #   # @param name [String] the user's name
        #   # @param age [Integer] the user's age
        #   def create_user(name, age)
        #   end
        #
        # ## Configuration
        #
        # To use type_first style instead:
        #
        #     Tags/TagTypePosition:
        #       EnforcedStyle: type_first
        #
        # @example Good - When EnforcedStyle is type_first
        #   # @param name [String] the user's name
        #   # @param age [Integer] the user's age
        #   def create_user(name, age)
        #   end
        #
        # To disable this validator:
        #
        #     Tags/TagTypePosition:
        #       Enabled: false
        module TagTypePosition
        end
      end
    end
  end
end
