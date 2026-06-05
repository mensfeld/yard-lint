# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module OrphanedDocComment
          # Result object for orphaned documentation comment offenses
          class Result < Results::Base
            self.default_severity = 'warning'
            self.offense_type = 'line'
            self.offense_name = 'OrphanedDocComment'

            # @param offense [Hash] offense data
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
