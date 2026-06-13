# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module InvalidDirectiveFormat
          # Result object for InvalidDirectiveFormat validation
          class Result < Results::Base
            self.default_severity = 'error'
            self.offense_type = 'line'
            self.offense_name = 'InvalidDirectiveFormat'

            # Build human-readable message for InvalidDirectiveFormat offense
            # @param offense [Hash] offense data with :message key
            # @return [String] formatted message
            def build_message(offense)
              offense[:message] || 'InvalidDirectiveFormat detected'
            end
          end
        end
      end
    end
  end
end
