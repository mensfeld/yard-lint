# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UnderfilledLines
          # Builds human-readable messages for UnderfilledLines violations.
          class MessagesBuilder
            class << self
              # @param offense [Hash] offense details with :actual_lines, :reflowed_lines,
              #   :widest_fill, :max_length and :object_name
              # @return [String] formatted message
              def call(offense)
                actual = offense[:actual_lines]
                reflowed = offense[:reflowed_lines]
                widest = offense[:widest_fill]
                max_length = offense[:max_length]
                object_name = offense[:object_name]

                "Documentation paragraph uses #{actual} lines but fits in #{reflowed} " \
                  "at <=#{max_length} cols [widest line filled to #{widest}/#{max_length}] " \
                  "for '#{object_name}'"
              end
            end
          end
        end
      end
    end
  end
end
