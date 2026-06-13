# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # CollectionType validator
        #
        # Enforces correct YARD collection type syntax for Hash types. YARD uses
        # `Hash{K => V}` syntax with curly braces and hash rockets, not the generic
        # `Hash<K, V>` syntax used in other languages and documentation tools.
        # This validator is enabled by default.
        #
        # ## Why This Matters
        #
        # YARD has specific syntax conventions that differ from other documentation tools.
        # Using the correct syntax ensures that YARD can properly parse and display your
        # type annotations in generated documentation.
        #
        # @example Bad - Generic syntax with angle brackets
        #   # @param options [Hash<Symbol, String>] configuration options
        #   # @param mapping [Hash<String, Integer>] key to value mapping
        #   def configure(options, mapping)
        #   end
        #
        # @example Good - YARD syntax with curly braces
        #   # @param options [Hash{Symbol => String}] configuration options
        #   # @param mapping [Hash{String => Integer}] key to value mapping
        #   def configure(options, mapping)
        #   end
        #
        # @example Good - Arrays use angle brackets (correct for YARD)
        #   # @param items [Array<String>] list of items
        #   # @param numbers [Array<Integer>] list of numbers
        #   def process(items, numbers)
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Tags/CollectionType:
        #       Enabled: false
        module CollectionType
        end
      end
    end
  end
end
