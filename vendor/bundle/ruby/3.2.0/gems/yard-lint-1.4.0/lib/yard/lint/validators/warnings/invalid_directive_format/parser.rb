# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module InvalidDirectiveFormat
          # Parser for InvalidDirectiveFormat warnings
          class Parser < ::Yard::Lint::Parsers::OneLineBase
            # Set of regexps for detecting warnings reported by YARD stats
            self.regexps = {
              general: /^\[warn\]: Invalid directive format/,
              message: /\[warn\]: (.*) in file/,
              location: /in file `(.*)`/,
              line: /line (\d*)/
            }.freeze
          end
        end
      end
    end
  end
end
