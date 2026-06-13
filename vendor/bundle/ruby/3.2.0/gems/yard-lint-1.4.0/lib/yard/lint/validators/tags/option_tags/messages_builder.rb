# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module OptionTags
          # Builds messages for option tag offenses
          class MessagesBuilder
            class << self
              # Build message for option tag offense
              # @param offense [Hash] offense data with :method_name key
              # @return [String] formatted message
              def call(offense)
                "Method `#{offense[:method_name]}` has options parameter but no @option tags " \
                  'documenting the available options'
              end
            end
          end
        end
      end
    end
  end
end
