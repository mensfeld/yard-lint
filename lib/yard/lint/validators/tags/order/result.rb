# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module Order
          # Result object for tag order validation
          # Transforms parsed tag order violations into offense objects
          class Result < Results::Base
            self.default_severity = 'convention'
            self.offense_type = 'method'
            self.offense_name = 'InvalidTagOrder'

            # Build human-readable message for tag order offense
            # @param offense [Hash] offense data with :method_name and :order keys
            # @return [String] formatted message
            def build_message(offense)
              MessagesBuilder.call(offense)
            end
          end
        end
      end
    end
  end
end
