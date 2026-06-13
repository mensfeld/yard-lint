# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module MarkdownSyntax
          # Builds human-readable messages for MarkdownSyntax violations
          class MessagesBuilder
            # Maps markdown syntax error types to human-readable descriptions
            ERROR_DESCRIPTIONS = {
              'unclosed_backtick' => 'Unclosed backtick in documentation',
              'unclosed_code_block' => 'Unclosed code block (```) in documentation',
              'unclosed_bold' => 'Unclosed bold formatting (**) in documentation',
              'invalid_list_marker' => 'Invalid list marker (use - or * instead)'
            }.freeze

            class << self
              # Formats a violation message
              # @param offense [Hash] the offense details
              # @return [String] formatted message
              def call(offense)
                object_name = offense[:object_name]
                errors = offense[:errors]

                error_messages = errors.map do |error|
                  if error.start_with?('invalid_list_marker:')
                    line_num = error.split(':').last
                    "#{ERROR_DESCRIPTIONS['invalid_list_marker']} at line #{line_num}"
                  else
                    ERROR_DESCRIPTIONS[error] || error
                  end
                end

                "Markdown syntax errors in '#{object_name}': " \
                  "#{error_messages.join(', ')}"
              end
            end
          end
        end
      end
    end
  end
end
