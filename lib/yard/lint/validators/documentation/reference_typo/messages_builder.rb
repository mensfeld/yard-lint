# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module ReferenceTypo
          # Builds human-readable messages for ReferenceTypo violations
          class MessagesBuilder
            class << self
              # Formats a reference typo violation message
              # @param offense [Hash] offense details with :reference and :suggestion keys
              # @return [String] formatted message
              def call(offense)
                "Reference '#{offense[:reference]}' does not resolve " \
                  "(did you mean '#{offense[:suggestion]}'?)"
              end
            end
          end
        end
      end
    end
  end
end
