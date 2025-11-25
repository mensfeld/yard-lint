# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module EmptyCommentLine
          # Builds human-readable messages for empty comment line violations
          class MessagesBuilder
            # Maps violation types to human-readable descriptions
            ERROR_DESCRIPTIONS = {
              'leading' => 'Empty leading comment line in documentation',
              'trailing' => 'Empty trailing comment line in documentation'
            }.freeze

            class << self
              # Formats a violation message
              # @param offense [Hash] the offense details
              # @return [String] formatted message
              def call(offense)
                type = offense[:violation_type]
                object_name = offense[:object_name]

                description = ERROR_DESCRIPTIONS[type] || 'Empty comment line in documentation'

                "#{description} for '#{object_name}'"
              end
            end
          end
        end
      end
    end
  end
end
