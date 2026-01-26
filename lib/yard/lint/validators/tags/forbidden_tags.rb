# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # ForbiddenTags validator
        #
        # Detects forbidden YARD tag and type combinations. This is useful for
        # enforcing project-specific documentation conventions, such as:
        # - Disallowing `@return [void]` (prefer documenting side effects)
        # - Forbidding overly generic types like `@param [Object]`
        # - Preventing use of certain tags entirely
        #
        # This validator is disabled by default (opt-in).
        #
        # ## Configuration
        #
        # To enable and configure forbidden patterns:
        #
        #     Tags/ForbiddenTags:
        #       Enabled: true
        #       Severity: convention
        #       ForbiddenPatterns:
        #         # Forbid @return [void]
        #         - Tag: return
        #           Types:
        #             - void
        #         # Forbid @param [Object]
        #         - Tag: param
        #           Types:
        #             - Object
        #         # Forbid @api tag entirely
        #         - Tag: api
        #
        # @example Bad - @return [void] (when configured as forbidden)
        #   # Does something
        #   # @return [void]
        #   def do_something
        #     puts "done"
        #   end
        #
        # @example Good - Document side effects instead
        #   # Prints 'done' to stdout
        #   # @return [nil] always returns nil after printing
        #   def do_something
        #     puts "done"
        #   end
        #
        # @example Bad - @param [Object] (when configured as forbidden)
        #   # Process data
        #   # @param data [Object] the data
        #   def process(data)
        #     data.to_s
        #   end
        #
        # @example Good - Use specific type
        #   # Process data
        #   # @param data [String, Integer] the data to process
        #   def process(data)
        #     data.to_s
        #   end
        module ForbiddenTags
        end
      end
    end
  end
end
