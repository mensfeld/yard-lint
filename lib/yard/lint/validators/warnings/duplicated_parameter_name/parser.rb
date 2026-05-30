# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module DuplicatedParameterName
          # Parser for DuplicatedParameterName warnings
          # YARD output format:
          #   [warn]: @param tag has duplicate parameter name: ...
          #       in file `filename.rb' near line N
          class Parser < ::Yard::Lint::Parsers::TwoLineBase
            # Set of regexps for detecting warnings reported by YARD stats
            self.regexps = {
              general: /^\[warn\]: @param tag has duplicate parameter name/,
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
