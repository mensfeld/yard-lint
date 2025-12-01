# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagGroupSeparator
          # Builds messages for missing tag group separator offenses.
          class MessagesBuilder
            class << self
              # Build message for missing tag group separator.
              #
              # @param offense [Hash] offense data with :method_name and :separators keys
              #
              # @return [String] formatted message
              def call(offense)
                transitions = parse_transitions(offense[:separators])

                if transitions.size == 1
                  from, to = transitions.first
                  "The `#{offense[:method_name]}` is missing a blank line between " \
                    "`#{from}` and `#{to}` tag groups."
                else
                  formatted = transitions.map { |from, to| "`#{from}` -> `#{to}`" }.join(', ')
                  "The `#{offense[:method_name]}` is missing blank lines between tag groups: " \
                    "#{formatted}."
                end
              end

              private

              # Parses transition string into array of [from, to] pairs.
              #
              # @param separators [String] string in format "from->to,from->to"
              #
              # @return [Array<Array<String>>] array of [from, to] pairs
              def parse_transitions(separators)
                separators
                  .to_s
                  .split(',')
                  .map { |transition| transition.split('->') }
              end
            end
          end
        end
      end
    end
  end
end
