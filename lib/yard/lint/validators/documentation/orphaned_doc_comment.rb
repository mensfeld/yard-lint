# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # OrphanedDocComment validator
        #
        # Detects YARD documentation comment blocks that contain tags (`@param`,
        # `@return`, etc.) but are not attached to any documentable Ruby construct.
        # YARD silently drops these comments - they never appear in the registry and
        # the documentation is permanently lost.
        #
        # This happens when a YARD-tagged comment is immediately followed by a
        # non-documentable statement (variable assignment, `require`, `include`, etc.)
        # or sits at the end of a file.
        #
        # @note This validator is complementary to `Documentation/BlankLineBeforeDefinition`,
        #   which catches doc blocks separated from a `def` by blank lines.
        #   `OrphanedDocComment` catches doc blocks that lead to non-definition code entirely.
        #
        # @example Bad - comment before variable assignment
        #   # @param name [String] the name
        #   # @return [void]
        #   MY_CONSTANT = "value"
        #
        # @example Bad - comment before require
        #   # @param name [String] the name
        #   require "some_gem"
        #
        # @example Bad - comment at end of file
        #   # @param name [String] the name
        #   # @return [void]
        #   # (EOF)
        #
        # @example Good - comment before def
        #   # @param name [String] the name
        #   # @return [void]
        #   def process(name)
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Documentation/OrphanedDocComment:
        #       Enabled: false
        module OrphanedDocComment
        end
      end
    end
  end
end
