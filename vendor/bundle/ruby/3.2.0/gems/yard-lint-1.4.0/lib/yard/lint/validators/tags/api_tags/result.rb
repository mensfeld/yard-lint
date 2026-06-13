# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ApiTags
          # Result object for API tag validation
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type = 'line'
            self.offense_name = 'ApiTagViolation'

            # Build human-readable message for API tag offense
            # @param offense [Hash] offense data with :name key
            # @return [String] formatted message
            def build_message(offense)
              MessagesBuilder.call(offense)
            end

            private

            # Override to build offenses with dynamic names from parsed data
            # @return [Array<Hash>] array of offense hashes
            def build_offenses
              @parsed_data.map do |offense_data|
                {
                  severity: configured_severity,
                  type: self.class.offense_type,
                  name: offense_data[:name] || self.class.offense_name,
                  message: build_message(offense_data),
                  location: offense_data[:location] || offense_data[:file],
                  location_line: offense_data[:line] || offense_data[:location_line] || 0
                }
              end
            end
          end
        end
      end
    end
  end
end
