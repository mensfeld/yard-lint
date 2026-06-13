# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedMethodArguments
          # Result object for undocumented method arguments validation
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type = 'method'
            self.offense_name = 'UndocumentedMethodArgument'

            # Build human-readable message for undocumented method argument offense
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
