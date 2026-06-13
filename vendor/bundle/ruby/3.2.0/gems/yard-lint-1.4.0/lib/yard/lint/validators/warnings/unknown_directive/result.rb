# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module UnknownDirective
          # Result object for UnknownDirective validation
          class Result < Results::Base
            self.default_severity = 'error'
            self.offense_type = 'line'
            self.offense_name = 'UnknownDirective'

            # Build human-readable message for UnknownDirective offense
            # @param offense [Hash] offense data with :message key
            # @return [String] formatted message
            def build_message(offense)
              offense[:message] || 'UnknownDirective detected'
            end
          end
        end
      end
    end
  end
end
