# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleStyle
          # Builds messages for example style offenses
          class MessagesBuilder
            class << self
              # Build message for example style offense
              # @param offense [Hash] offense data with :example_name, :cop_name, :message keys
              # @return [String] formatted message
              def call(offense)
                example_name = offense[:example_name]
                cop_name = offense[:cop_name]
                message = offense[:message]
                object_name = offense[:object_name]

                "Object `#{object_name}` has style offense in @example " \
                  "'#{example_name}': #{cop_name}: #{message}"
              end
            end
          end
        end
      end
    end
  end
end
