# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module MissingReturn
          # Result object for missing return tag validation
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type = 'line'
            self.offense_name = 'MissingReturnTag'

            # Build human-readable message for missing return tag offense
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
