# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module MissingYield
          # Builds messages for missing yield tag offenses
          class MessagesBuilder
            class << self
              # @param offense [Hash] offense data with :element key
              # @return [String] formatted message
              def call(offense)
                "Method `#{offense[:element]}` yields to a block but is missing a @yield, @yieldparam, or @yieldreturn tag"
              end
            end
          end
        end
      end
    end
  end
end
