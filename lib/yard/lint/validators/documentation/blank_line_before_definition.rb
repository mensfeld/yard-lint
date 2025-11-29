# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # BlankLineBeforeDefinition validator
        #
        # Detects blank lines between YARD documentation and method/class/module definitions.
        # YARD requires documentation to be immediately adjacent to the definition it documents.
        #
        # @example Bad - Single blank line (convention violation)
        #   # Description of the method
        #   # @param value [String] the value
        #
        #   def process(value)
        #   end
        #
        # @example Bad - Multiple blank lines (orphaned documentation)
        #   # Description of the method
        #   # @param value [String] the value
        #
        #
        #   def process(value)
        #   end
        #
        # @example Good - No blank lines
        #   # Description of the method
        #   # @param value [String] the value
        #   def process(value)
        #   end
        #
        # ## Severity Levels
        #
        # - **1 blank line**: Convention violation - YARD associates the doc but this
        #   violates formatting conventions
        # - **2+ blank lines**: Orphaned documentation - YARD ignores the documentation entirely
        #
        # ## Configuration
        #
        # To customize severity levels:
        #
        #     Documentation/BlankLineBeforeDefinition:
        #       Severity: warning           # For single blank line
        #       OrphanedSeverity: error     # For 2+ blank lines
        #
        # To check only single blank lines:
        #
        #     Documentation/BlankLineBeforeDefinition:
        #       EnabledPatterns:
        #         SingleBlankLine: true
        #         OrphanedDocs: false
        #
        # To disable this validator:
        #
        #     Documentation/BlankLineBeforeDefinition:
        #       Enabled: false
        module BlankLineBeforeDefinition
        end
      end
    end
  end
end
