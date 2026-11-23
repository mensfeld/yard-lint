# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedBooleanMethods
          # Builds messages for undocumented boolean methods offenses
          class MessagesBuilder
            class << self
              # Build message for a documented boolean method without a @return tag
              # @param offense [Hash] offense data with :element key
              # @return [String] formatted message
              def call(offense)
                "The `#{offense[:element]}` method has no @return tag"
              end
            end
          end
        end
      end
    end
  end
end
