# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module LineLength
          # Result wrapper for LineLength validator.
          class Result < Results::Base
            self.default_severity = 'convention'
            self.offense_type = 'line'
            self.offense_name = 'LineLength'

            private

            # @param offense [Hash] offense details including :max_length from the validator
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
