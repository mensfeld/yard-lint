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
              # Opt-in: also skip 4-space (or tab) indented Markdown code blocks,
              # not just fenced (```) blocks. Off by default because indented
              # content is also used for list continuations and wrapped prose,
              # which would then be skipped too.
              'SkipIndentedCodeBlocks' => false,
              'Patterns' => {
                'Note' => '@note',
                'IMPORTANT' => '@note',
                'Important' => '@note',
                'Todo' => '@todo',
                'TODO' => '@todo',
                'FIXME' => '@todo',
                'See' => '@see',
                'See also' => '@see',
                'Warning' => '@note',
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
