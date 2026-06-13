# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module SyntaxError
          # Parser for SyntaxError warnings.
          #
          # YARD reports a parse failure as a single warning line of the form:
          #   Syntax error in `path/to/file.rb`:(LINE,COL): <description>
          # (a sibling `ParserSyntaxError:` line and a stack trace are also
          # emitted, but the `general` pattern matches only the first so each
          # failure yields exactly one offense).
          class Parser < ::Yard::Lint::Parsers::OneLineBase
            # Set of regexps for detecting syntax-error warnings reported by YARD
            self.regexps = {
              general: /^\[warn\]: Syntax error in /,
              message: /:\(\d+,\d+\):\s*(.+)$/,
              location: /Syntax error in `(.+?)`/,
              line: /:\((\d+),\d+\):/
            }.freeze
          end
        end
      end
    end
  end
end
