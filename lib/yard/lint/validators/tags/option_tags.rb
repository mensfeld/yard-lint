# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # OptionTags validator
        #
        # Ensures that methods with options parameters document them using `@option`
        # tags. This validator is enabled by default.
        #
        # @example Configuration - Disable if needed
        #   Tags/OptionTags:
        #     Enabled: false
        #
        # @example Good - Options hash is documented
        #   # @param name [String] the name
        #   # @param options [Hash] configuration options
        #   # @option options [Boolean] :enabled Whether to enable the feature
        #   # @option options [Integer] :timeout Timeout in seconds
        #   def configure(name, options = {})
        #   end
        #
        # @example Bad - Missing @option tags
        #   # @param name [String] the name
        #   # @param options [Hash] configuration options
        #   def configure(name, options = {})
        #   end
        #
        module OptionTags
        end
      end
    end
  end
end
