# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedObjects
          # Result object for undocumented objects validation
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type = 'line'
            self.offense_name = 'UndocumentedObject'

            # Build human-readable message for undocumented object offense
            # @param offense [Hash] offense data
            # @return [String] formatted message
            def build_message(offense)
              # Offenses of the combined UndocumentedBooleanMethods carry :method_name
              if offense.key?(:method_name)
                UndocumentedBooleanMethods::MessagesBuilder.call(offense)
              else
                MessagesBuilder.call(offense)
              end
            end
          end
        end
      end
    end
  end
end
