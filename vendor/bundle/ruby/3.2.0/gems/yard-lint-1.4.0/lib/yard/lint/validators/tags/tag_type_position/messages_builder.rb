# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagTypePosition
          # Builds human-readable messages for TagTypePosition violations
          class MessagesBuilder
            class << self
              # Formats a violation message
              # @param offense [Hash] the offense details
              # @return [String] formatted message
              def call(offense)
                tag_name = offense[:tag_name]
                param_name = offense[:param_name]
                type_info = offense[:type_info]
                detected_style = offense[:detected_style]

                if detected_style == 'type_after_name'
                  # Enforcing type_first, but found type_after_name
                  "Type should appear before parameter name in @#{tag_name} tag. " \
                    "Use '@#{tag_name} [#{type_info}] #{param_name}' instead of " \
                    "'@#{tag_name} #{param_name} [#{type_info}]'."
                else
                  # Enforcing type_after_name, but found type_first
                  "Type should appear after parameter name in @#{tag_name} tag. " \
                    "Use '@#{tag_name} #{param_name} [#{type_info}]' instead of " \
                    "'@#{tag_name} [#{type_info}] #{param_name}'."
                end
              end
            end
          end
        end
      end
    end
  end
end
