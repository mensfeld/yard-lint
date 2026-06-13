# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedObjects
          # Builds messages for undocumented objects offenses
          class MessagesBuilder
            class << self
              # Build message for an undocumented object
              # @param offense [Hash] offense data with :element key
              # @return [String] formatted message
              def call(offense)
                "Documentation required for `#{offense[:element]}`"
              end
            end
          end
        end
      end
    end
  end
end
