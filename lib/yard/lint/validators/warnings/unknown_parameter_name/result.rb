# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module UnknownParameterName
          # Result object for UnknownParameterName validation
          class Result < Results::Base
            self.default_severity = 'error'
            self.offense_type = 'line'
            self.offense_name = 'UnknownParameterName'

            # Build human-readable message for UnknownParameterName offense
            # Uses MessagesBuilder to add "did you mean" suggestions
            # @param offense [Hash] offense data with :message, :location, :line keys
            # @return [String] formatted message with suggestion if available
            def build_message(offense)
              MessagesBuilder.call(offense)
            end
          end
        end
      end
    end
  end
end
