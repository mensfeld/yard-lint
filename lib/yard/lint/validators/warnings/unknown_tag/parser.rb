# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module UnknownTag
          # Parser used to extract warnings details that are related to yard unknown tags
          # @example Output format (skip-lint)
          #   [warn]: Unknown tag @example1 in file `/builds/path/engine.rb` near line 32
          class Parser < ::Yard::Lint::Parsers::OneLineBase
            # Set of regexps for detecting warnings reported by YARD stats
            self.regexps = {
              general: /^\[warn\]: Unknown tag.*@.*near line/,
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
