# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module MissingReturn
          # Builds messages for missing return tag offenses
          class MessagesBuilder
            class << self
              # Build message for a method missing @return tag
              # @param offense [Hash] offense data with :element key
              # @return [String] formatted message
              def call(offense)
                "Missing @return tag for `#{offense[:element]}`"
              end
            end
          end
        end
      end
    end
  end
end
