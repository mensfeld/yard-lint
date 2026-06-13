# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # EmptyCommentLine validator
        #
        # Detects empty comment lines at the start or end of YARD documentation blocks.
        # Empty lines BETWEEN tag groups are allowed for readability.
        #
        # @example Bad - Empty leading comment line
        #   #
        #   # Description of the method
        #   # @param value [String] the value
        #   def process(value)
        #   end
        #
        # @example Bad - Empty trailing comment line
        #   # Description of the method
        #   # @param value [String] the value
        #   #
        #   def process(value)
        #   end
        #
        # @example Good - No leading or trailing empty lines
        #   # Description of the method
        #   # @param value [String] the value
        #   def process(value)
        #   end
        #
        # @example Good - Empty line between sections (allowed)
        #   # Description of the method
        #   #
        #   # @param value [String] the value
        #   # @return [Boolean] success
        #   def process(value)
        #   end
        #
        # ## Configuration
        #
        # To check only leading empty lines:
        #
        #     Documentation/EmptyCommentLine:
        #       EnabledPatterns:
        #         Leading: true
        #         Trailing: false
        #
        # To disable this validator:
        #
        #     Documentation/EmptyCommentLine:
        #       Enabled: false
        module EmptyCommentLine
        end
      end
    end
  end
end
