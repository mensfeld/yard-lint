# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # ApiTags validator
        #
        # Enforces that all public classes, modules, and methods have an `@api` tag
        # to explicitly document their API visibility level. This validator is disabled
        # by default and must be explicitly enabled.
        #
        # ## Configuration
        #
        # To enable this validator (it's disabled by default):
        #
        #     Tags/ApiTags:
        #       Enabled: true
        #       AllowedApis:
        #         - public
        #         - private
        #
        # @example Good - Methods and classes have @api tags
        #   # @api public
        #   class MyClass
        #     # @api public
        #     def public_method
        #     end
        #
        #     # @api private
        #     def internal_helper
        #     end
        #   end
        #
        # @example Bad - Missing @api tags
        #   class AnotherClass
        #     def some_method
        #     end
        #   end
        #
        module ApiTags
        end
      end
    end
  end
end
