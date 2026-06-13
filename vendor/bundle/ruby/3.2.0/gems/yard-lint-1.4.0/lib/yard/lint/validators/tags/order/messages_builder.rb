# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module Order
          # Builds messages for invalid tag order offenses
          class MessagesBuilder
            class << self
              # Build message for invalid tag order
              # @param offense [Hash] offense data with :method_name and :order keys
              # @return [String] formatted message
              def call(offense)
                expected_order = offense[:order]
                                 .to_s
                                 .split(',')
                                 .map { |tag| "`#{tag}`" }
                                 .join(', ')

                "The `#{offense[:method_name]}` has yard tags in an invalid order. " \
                  "Following tags need to be in the presented order: #{expected_order}."
              end
            end
          end
        end
      end
    end
  end
end
