# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module DuplicatedParameterName
          # Result object for DuplicatedParameterName validation
          class Result < Results::Base
            self.default_severity = 'error'
            self.offense_type = 'line'
            self.offense_name = 'DuplicatedParameterName'

            # Build human-readable message for DuplicatedParameterName offense
            # @param offense [Hash] offense data with :message key
            # @return [String] formatted message
            def build_message(offense)
              offense[:message] || 'DuplicatedParameterName detected'
            end
          end
        end
      end
    end
  end
end
