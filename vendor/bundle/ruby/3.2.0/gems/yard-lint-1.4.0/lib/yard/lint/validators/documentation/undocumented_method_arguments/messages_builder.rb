# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedMethodArguments
          # Builds messages for undocumented method arguments offenses
          class MessagesBuilder
            class << self
              # Build message for undocumented method arguments
              # @param offense [Hash] offense data with :method_name key
              # @return [String] formatted message
              def call(offense)
                "The `#{offense[:method_name]}` method is missing documentation " \
                  'for some of the arguments.'
              end
            end
          end
        end
      end
    end
  end
end
