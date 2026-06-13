# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ForbiddenTags
          # Result wrapper for ForbiddenTags validator
          # Formats parsed violations into offense objects
          class Result < Results::Base
            self.default_severity = 'convention'
            self.offense_type = 'tag'
            self.offense_name = 'ForbiddenTags'

            private

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
