# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module TextSubstitution
          # Builds human-readable messages for TextSubstitution violations.
          class MessagesBuilder
            TRUNCATE_AT = 60

            class << self
              # @param offense [Hash]
              # @return [String]
              def call(offense)
                forbidden   = offense[:forbidden]
                replacement = offense[:replacement]
                line_text   = offense[:line_text]

                message = "Replace '#{forbidden}' with '#{replacement}' in documentation"

                if line_text && !line_text.empty?
                  truncated = line_text.length > TRUNCATE_AT \
                    ? "#{line_text[0, TRUNCATE_AT - 3]}..." \
                    : line_text
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
