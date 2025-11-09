# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module MeaninglessTag
          # Result wrapper for MeaninglessTag validator
          # Formats parsed violations into offense objects
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type = 'class'
            self.offense_name = 'MeaninglessTag'

            # Builds a human-readable message for the offense
            # @param offense [Hash] offense details
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
