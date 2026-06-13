# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module UnknownDirective
          # Parser for UnknownDirective warnings
          class Parser < ::Yard::Lint::Parsers::OneLineBase
            # Set of regexps for detecting warnings reported by YARD stats
            self.regexps = {
              general: /^\[warn\]: Unknown directive.*@!.*near line/,
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
