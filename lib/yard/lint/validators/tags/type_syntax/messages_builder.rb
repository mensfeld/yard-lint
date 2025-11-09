# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TypeSyntax
          # Builds human-readable messages for type syntax violations
          class MessagesBuilder
            class << self
              # Formats a type syntax violation message
              # @param offense [Hash] offense details with tag_name, type_string, error_message
              # @return [String] formatted message
              def call(offense)
                tag = offense[:tag_name]
                type = offense[:type_string]
                error = offense[:error_message]

                "Invalid type syntax in @#{tag} tag: '#{type}' (#{error})"
              end
            end
          end
        end
      end
    end
  end
end
