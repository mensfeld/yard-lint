# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InformalNotation
          # Builds human-readable messages for InformalNotation violations
          class MessagesBuilder
            class << self
              # Formats an informal notation violation message
              # @param offense [Hash] offense details with :pattern, :replacement, :object_name keys
              # @return [String] formatted message
              def call(offense)
                pattern = offense[:pattern]
                replacement = offense[:replacement]
                line_text = offense[:line_text]

                message = "Use #{replacement} tag instead of '#{pattern}:' notation"

                if line_text && !line_text.empty?
                  # Truncate long lines for readability
                  truncated = line_text.length > 60 ? "#{line_text[0..57]}..." : line_text
                  message += ". Found: \"#{truncated}\""
                end

                message
              end
            end
          end
        end
      end
    end
  end
end
