# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UnderfilledLines
          # Result wrapper for UnderfilledLines validator.
          class Result < Results::Base
            self.default_severity = 'convention'
            self.offense_type = 'line'
            self.offense_name = 'UnderfilledLines'

            private

            # @param offense [Hash] offense details from the parser
            # @return [String] formatted message
            def build_message(offense)
              MessagesBuilder.call(offense)
            end
          end
        end
      end
    end
  end
end
