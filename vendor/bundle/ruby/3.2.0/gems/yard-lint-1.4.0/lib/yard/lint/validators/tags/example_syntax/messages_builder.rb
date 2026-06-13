# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleSyntax
          # Builds messages for example syntax offenses
          class MessagesBuilder
            class << self
              # Build message for example syntax offense
              # @param offense [Hash] offense data with :example_name and :error_message keys
              # @return [String] formatted message
              def call(offense)
                example_name = offense[:example_name]
                error_msg = offense[:error_message]
                object_name = offense[:object_name]

                "Object `#{object_name}` has syntax error in @example " \
                  "'#{example_name}': #{error_msg}"
              end
            end
          end
        end
      end
    end
  end
end
