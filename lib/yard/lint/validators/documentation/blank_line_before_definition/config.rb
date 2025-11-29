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
              }
            }.freeze
          end
        end
      end
    end
  end
end
