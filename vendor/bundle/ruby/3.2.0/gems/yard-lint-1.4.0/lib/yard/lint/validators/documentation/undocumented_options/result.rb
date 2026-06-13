# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedOptions
          # Result object for undocumented options validation
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type = 'line'
            self.offense_name = 'UndocumentedOptions'

            # Build human-readable message for undocumented options offense
            # @param offense [Hash] offense data with :object_name and :params
            # @return [String] formatted message
            def build_message(offense)
              object_name = offense[:object_name]
              params = offense[:params]

              "Method '#{object_name}' has options parameter (#{params}) " \
                'but no @option tags in documentation.'
            end
          end
        end
      end
    end
  end
end
