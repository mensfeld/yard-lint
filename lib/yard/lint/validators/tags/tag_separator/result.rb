# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagSeparator
          # Result object for tag separator validation.
          # Transforms parsed separator violations into offense objects.
          class Result < Results::Base
            self.default_severity = "convention"
            self.offense_type = "method"
            self.offense_name = "MissingTagSeparator"

            # Build human-readable message for tag separator offense.
            #
            # @param offense [Hash] offense data with :method_name and :separators keys
            #
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
