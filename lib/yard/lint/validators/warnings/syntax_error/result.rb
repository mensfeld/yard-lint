# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module SyntaxError
          # Result object for SyntaxError validation
          class Result < Results::Base
            self.default_severity = 'error'
            self.offense_type = 'line'
            self.offense_name = 'SyntaxError'

            # Build human-readable message for a SyntaxError offense
            # @param offense [Hash] offense data with :message key
            # @return [String] formatted message
            def build_message(offense)
              base = 'File could not be parsed by YARD and was skipped'
              detail = offense[:message]
              detail && !detail.empty? ? "#{base}: #{detail}" : base
            end
          end
        end
      end
    end
  end
end
