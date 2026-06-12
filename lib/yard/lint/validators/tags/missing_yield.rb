# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # MissingYield validator
        #
        # Detects methods that call `yield` in their body but do not document
        # the block with a `@yield`, `@yieldparam`, or `@yieldreturn` tag.
        # Callers need to know a method yields so they can pass a block;
        # undocumented yield is a silent API contract that only source readers discover.
        #
        # This validator is disabled by default (opt-in).
        #
        # @example Bad - method yields but block is undocumented
        #   # Iterates over items
        #   # @param items [Array] the items
        #   def each(items)
        #     items.each { |item| yield item }
        #   end
        #
        # @example Good - block documented with @yield
        #   # Iterates over items
        #   # @param items [Array] the items
        #   # @yield [item] each item in the collection
        #   def each(items)
        #     items.each { |item| yield item }
        #   end
        #
        # @example Good - block documented with @yieldparam
        #   # @param items [Array] the items
        #   # @yieldparam item [Object] each item
        #   def each(items)
        #     items.each { |item| yield item }
        #   end
        #
        # @note Does not flag the inverse case (has `@yield` tag but no actual
        #   `yield` in source) - that is intentional for abstract/overridable methods.
        #
        # @note Known limitation: `yield` appearing inside heredoc bodies or
        #   multi-line string literals may produce false positives. These cases
        #   are rare enough in practice that the validator does not attempt to
        #   handle them.
        #
        # ## Configuration
        #
        #     Tags/MissingYield:
        #       Enabled: true
        #       Severity: warning
        module MissingYield
        end
      end
    end
  end
end
