# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InvalidTypes
          # Builds messages for invalid tag types offenses
          class MessagesBuilder
            class << self
              # Build message for invalid tag types
              # @param offense [Hash] offense data with :method_name key
              # @return [String] formatted message
              def call(offense)
                "The `#{offense[:method_name]}` has at least one tag " \
                  'with an invalid type definition.'
              end
            end
          end
        end
      end
    end
  end
end
