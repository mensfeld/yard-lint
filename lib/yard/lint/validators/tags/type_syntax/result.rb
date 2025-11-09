# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TypeSyntax
          # Result wrapper for TypeSyntax validator
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type = 'method'
            self.offense_name = 'InvalidTypeSyntax'

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
