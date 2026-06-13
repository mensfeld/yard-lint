# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module UnknownParameterName
          # Parser for UnknownParameterName warnings
          class Parser < ::Yard::Lint::Parsers::TwoLineBase
            # Set of regexps for detecting warnings reported by YARD stats
            # YARD output format:
            #   [warn]: @param tag has unknown parameter name: ...
            #       in file `filename.rb' near line 8
            self.regexps = {
              general: /^\[warn\]: @param tag has unknown parameter name/,
              message: /\[warn\]: (.*)$/,
              location: /in file `(.*?)'\s*near/,
              line: /near line (\d+)/
            }.freeze
          end
        end
      end
    end
  end
end
