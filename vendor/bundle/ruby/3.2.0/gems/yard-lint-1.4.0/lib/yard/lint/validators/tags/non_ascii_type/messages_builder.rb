# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module NonAsciiType
          # Builds human-readable messages for non-ASCII type violations
          class MessagesBuilder
            class << self
              # Formats a non-ASCII type violation message
              # @param offense [Hash] offense details with tag_name, type_string, character, codepoint
              # @return [String] formatted message
              def call(offense)
                tag = offense[:tag_name]
                type = offense[:type_string]
                char = offense[:character]
                codepoint = offense[:codepoint]

                "Type specification in @#{tag} tag contains non-ASCII character " \
                  "'#{char}' (#{codepoint}) in '#{type}'. Ruby type names must use ASCII characters only."
              end
            end
          end
        end
      end
    end
  end
end
