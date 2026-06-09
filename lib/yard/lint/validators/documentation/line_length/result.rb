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

            # @param offense [Hash] offense details
            # @return [String] formatted message
            def build_message(offense)
              max_length = config&.validator_config(validator_name, 'MaxLength') ||
                           LineLength::Config.defaults['MaxLength']
              MessagesBuilder.call(offense.merge(max_length: max_length))
            end
          end
        end
      end
    end
  end
end
