# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module InvalidTagFormat
          # Result object for InvalidTagFormat validation
          class Result < Results::Base
            self.default_severity = 'error'
            self.offense_type = 'line'
            self.offense_name = 'InvalidTagFormat'

            # Build human-readable message for InvalidTagFormat offense
            # @param offense [Hash] offense data with :message key
            # @return [String] formatted message
            def build_message(offense)
              offense[:message] || 'InvalidTagFormat detected'
            end
          end
        end
      end
    end
  end
end
