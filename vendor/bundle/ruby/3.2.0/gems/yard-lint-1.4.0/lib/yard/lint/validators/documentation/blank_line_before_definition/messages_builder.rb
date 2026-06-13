# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module BlankLineBeforeDefinition
          # Builds human-readable messages for blank line before definition violations
          class MessagesBuilder
            # Maps violation types to human-readable descriptions
            ERROR_DESCRIPTIONS = {
              'single' => 'Blank line between documentation and definition',
              'orphaned' => 'Documentation is orphaned (YARD ignores it due to blank lines)'
            }.freeze

            class << self
              # Formats a violation message
              # @param offense [Hash] the offense details
              # @return [String] formatted message
              def call(offense)
                type = offense[:violation_type]
                object_name = offense[:object_name]
                blank_count = offense[:blank_count]

                description = ERROR_DESCRIPTIONS[type] || 'Blank line before definition'

                if type == 'orphaned'
                  "#{description} for '#{object_name}' (#{blank_count} blank lines)"
                else
                  "#{description} for '#{object_name}'"
                end
              end
            end
          end
        end
      end
    end
  end
end
