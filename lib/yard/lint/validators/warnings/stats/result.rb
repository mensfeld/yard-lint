# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module Stats
          # Result object for YARD warnings validation
          # Handles all warning types: UnknownTag, UnknownDirective, UnknownParameterName,
          # InvalidTagFormat, InvalidDirectiveFormat, DuplicatedParameterName
          class Result < Results::Base
            self.default_severity = 'error'
            self.offense_type = 'line'
            self.offense_name = 'YardWarning'

            # Build human-readable message for warning offense
            # @param offense [Hash] offense data with :message key
            # @return [String] formatted message
            def build_message(offense)
              offense[:message]
            end

            private

            # Override to build offenses with dynamic names and configured severity
            # @return [Array<Hash>] array of offense hashes
            def build_offenses
              @parsed_data.map do |offense_data|
                # Map warning name to validator name for severity lookup
                warning_name = offense_data[:name] || self.class.offense_name
                validator_name = "Warnings/#{warning_name}"
                severity = config&.validator_severity(validator_name) ||
                           self.class.default_severity

                {
                  severity: severity,
                  type: self.class.offense_type,
                  name: warning_name,
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
