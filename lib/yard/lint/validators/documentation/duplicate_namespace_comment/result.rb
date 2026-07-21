# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module DuplicateNamespaceComment
          # Result object for duplicate namespace comment validation
          # Transforms parsed offenses into offense objects
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type = 'line'
            self.offense_name = 'DuplicateNamespaceComment'

            # Build human-readable message for a duplicate namespace comment offense
            # @param offense [Hash] offense data with :namespace, :sites and :conflict keys
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
