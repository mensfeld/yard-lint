# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InvalidTypes
          # Result object for invalid tag types validation
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type = 'method'
            self.offense_name = 'InvalidTagType'

            # Build human-readable message for invalid tag type offense
            # @param offense [Hash] offense data
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
