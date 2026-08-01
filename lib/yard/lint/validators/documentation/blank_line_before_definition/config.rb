# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module BlankLineBeforeDefinition
          # Configuration for BlankLineBeforeDefinition validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :blank_line_before_definition
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'convention',
              'OrphanedSeverity' => 'convention',
              'EnabledPatterns' => {
                'SingleBlankLine' => true,
                'OrphanedDocs' => true
              },
              # Comment lines matching any of these patterns are not treated as
              # documentation, so a blank line below them is not reported as a
              # detached docstring. Each entry is a `/regex/` or a literal matched
              # at word boundaries. Useful for commented-out code, `# FIXME`
              # notes, etc.
              'IgnoredCommentPatterns' => []
            }.freeze
          end
        end
      end
    end
  end
end
