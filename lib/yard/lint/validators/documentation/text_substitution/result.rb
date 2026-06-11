# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module TextSubstitution
          # Result wrapper for TextSubstitution violations
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type     = 'line'
            self.offense_name     = 'TextSubstitution'

            # @param offense [Hash]
            # @return [String]
            def build_message(offense)
              MessagesBuilder.call(offense)
            end
          end
        end
      end
    end
  end
end
