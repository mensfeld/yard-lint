# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # UndocumentedOptions validator
        #
        # Checks that options hashes have detailed documentation about their keys.
        # When a method accepts an options hash parameter, the individual option
        # keys should be documented using `@option` tags. This validator is enabled
        # by default.
        #
        # @example Bad - Options parameter without @option tags
        #   # Configures the service
        #   # @param options [Hash] configuration options
        #   def configure(options)
        #   end
        #
        # @example Good - Options keys documented with @option tags
        #   # Configures the service
        #   # @param options [Hash] configuration options
        #   # @option options [Boolean] :enabled Whether to enable the feature
        #   # @option options [Integer] :timeout Connection timeout in seconds
        #   def configure(options)
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Documentation/UndocumentedOptions:
        #       Enabled: false
        #
        module UndocumentedOptions
        end
      end
    end
  end
end
