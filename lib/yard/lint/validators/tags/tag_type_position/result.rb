# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagTypePosition
          # Result wrapper for TagTypePosition violations
          class Result < Results::Base
            self.default_severity = 'convention'
            self.offense_type = 'style'
            self.offense_name = 'TagTypePosition'

            # Builds a human-readable message for a violation
            # @param offense [Hash] the offense details
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
