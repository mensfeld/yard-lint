# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module TextSubstitution
          # Builds human-readable messages for TextSubstitution violations.
          class MessagesBuilder
            class << self
              # @param offense [Hash] offense details with :forbidden, :replacement, :line_text keys
              # @return [String] formatted message
              def call(offense)
                forbidden   = offense[:forbidden]
                replacement = offense[:replacement]
                line_text   = offense[:line_text]

                message = "Replace '#{forbidden}' with '#{replacement}' in documentation"

                if line_text && !line_text.empty?
                  truncated = line_text.length > 60 ? "#{line_text[0, 57]}..." : line_text
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
