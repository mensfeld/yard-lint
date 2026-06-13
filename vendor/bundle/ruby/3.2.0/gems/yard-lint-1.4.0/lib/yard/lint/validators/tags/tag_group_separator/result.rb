# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagGroupSeparator
          # Result object for tag group separator validation.
          # Transforms parsed separator violations into offense objects.
          class Result < Results::Base
            self.default_severity = 'convention'
            self.offense_type = 'method'
            self.offense_name = 'MissingTagGroupSeparator'

            # Build human-readable message for tag group separator offense.
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
