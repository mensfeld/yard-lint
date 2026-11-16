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
              # @param offense [Hash] offense data with :method_name and
              #   :missing_params keys
              # @return [String] formatted message
              def call(offense)
                missing = Array(offense[:missing_params])

                if missing.empty?
                  "The `#{offense[:method_name]}` method is missing documentation " \
                    'for some of the arguments.'
                else
                  "The `#{offense[:method_name]}` method has no @param for: #{missing.join(', ')}"
                end
              end
            end
          end
        end
      end
    end
  end
end
