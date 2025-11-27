# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InformalNotation
          # Configuration for InformalNotation validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :informal_notation
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              'CaseSensitive' => false,
              'RequireStartOfLine' => true,
              'Patterns' => {
                'Note' => '@note',
                'Todo' => '@todo',
                'TODO' => '@todo',
                'FIXME' => '@todo',
                'See' => '@see',
                'See also' => '@see',
                'Warning' => '@deprecated',
                'Deprecated' => '@deprecated',
                'Author' => '@author',
                'Version' => '@version',
                'Since' => '@since',
                'Returns' => '@return',
                'Raises' => '@raise',
                'Example' => '@example'
              }
            }.freeze
          end
        end
      end
    end
  end
end
