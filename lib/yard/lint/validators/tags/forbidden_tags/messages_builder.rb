# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ForbiddenTags
          # Builds human-readable messages for ForbiddenTags violations
          class MessagesBuilder
            class << self
              # Formats a forbidden tag violation message
              # @param offense [Hash] offense details with :tag_name, :types_text, :pattern_types
              # @return [String] formatted message
              def call(offense)
                tag_name = offense[:tag_name]
                types_text = offense[:types_text]
                pattern_types = offense[:pattern_types]

                if pattern_types.nil? || pattern_types.empty?
                  "Forbidden tag detected: @#{tag_name}. " \
                    'This tag is not allowed by project configuration.'
                else
                  type_display = types_text.empty? ? '' : " [#{types_text}]"
                  "Forbidden tag pattern detected: @#{tag_name}#{type_display}. " \
                    "Type(s) '#{pattern_types}' are not allowed for @#{tag_name}."
                end
              end
            end
          end
        end
      end
    end
  end
end
