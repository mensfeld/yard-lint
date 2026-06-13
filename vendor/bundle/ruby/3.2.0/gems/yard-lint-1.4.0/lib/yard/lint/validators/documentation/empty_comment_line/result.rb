# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module EmptyCommentLine
          # Result builder for empty comment line violations
          class Result < Results::Base
            self.default_severity = 'convention'
            self.offense_type = 'line'
            self.offense_name = 'EmptyCommentLine'

            # Build human-readable message for empty comment line offense
            # @param offense [Hash] offense data with violation details
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
