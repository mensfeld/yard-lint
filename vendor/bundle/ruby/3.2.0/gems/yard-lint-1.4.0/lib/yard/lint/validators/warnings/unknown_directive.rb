# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Validators for checking YARD warnings
      module Warnings
        # UnknownDirective validator
        #
        # Detects usage of unrecognized YARD directives in documentation. Directives
        # are special YARD commands (like `@!attribute`, `@!method`) that control
        # documentation generation. This validator flags unknown directives that
        # could indicate errors. This validator is enabled by default.
        #
        # @example Bad - Unknown or misspelled directive
        #   # @!attribute [r] name
        #   # @!method foo
        #   class User
        #   end
        #
        # @example Good - Standard YARD directives
        #   # @!attribute [r] name
        #   # @!method foo
        #   class User
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Warnings/UnknownDirective:
        #       Enabled: false
        #
        module UnknownDirective
        end
      end
    end
  end
end
