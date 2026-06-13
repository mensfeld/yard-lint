# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module RedundantParamDescription
          # Result builder for redundant parameter description violations
          class Result < Results::Base
            self.default_severity = 'convention'
            self.offense_type = 'tag'
            self.offense_name = 'RedundantParamDescription'

            # Build human-readable message for redundant param offense
            # @param offense [Hash] offense data with redundancy details
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
