# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module LineLength
          # Builds human-readable messages for LineLength violations.
          class MessagesBuilder
            class << self
              # @param offense [Hash] offense details with :length, :object_name, and config :max_length
              # @return [String] formatted message
              def call(offense)
                length = offense[:length]
                object_name = offense[:object_name]
                max_length = offense[:max_length]

                "Documentation line is too long [#{length} > #{max_length}] for '#{object_name}'"
              end
            end
          end
        end
      end
    end
  end
end
