# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module BlankLineBeforeDefinition
          # Result builder for blank line before definition violations
          class Result < Results::Base
            self.default_severity = 'convention'
            self.offense_type = 'line'
            self.offense_name = 'BlankLineBeforeDefinition'

            # Build human-readable message for blank line violation
            # @param offense [Hash] offense data with violation details
            # @return [String] formatted message
            def build_message(offense)
              MessagesBuilder.call(offense)
            end

            private

            # Override to handle per-violation severity based on violation type
            # @return [Array<Hash>] array of offense hashes
            def build_offenses
              @parsed_data.map do |offense_data|
                severity = severity_for_violation(offense_data[:violation_type])

                offense_data.merge(
                  severity: severity,
                  type: self.class.offense_type,
                  name: computed_offense_name,
                  message: build_message(offense_data),
                  location: offense_data[:location] || offense_data[:file],
                  location_line: offense_data[:line] || offense_data[:location_line] || 0
                )
              end
            end

            # Get severity for a specific violation type
            # @param violation_type [String] 'single' or 'orphaned'
            # @return [String] severity level
            def severity_for_violation(violation_type)
              default = self.class.default_severity
              return default unless config

              case violation_type
              when 'orphaned'
                config.validator_config(validator_name, 'OrphanedSeverity') ||
                  config.validator_severity(validator_name) ||
                  default
              else
                config.validator_severity(validator_name) || default
              end
            end
          end
        end
      end
    end
  end
end
