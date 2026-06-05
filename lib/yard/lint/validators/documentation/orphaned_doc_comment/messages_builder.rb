# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module OrphanedDocComment
          # Builds messages for orphaned documentation comment offenses
          class MessagesBuilder
            class << self
              # @param offense [Hash] offense data with :tags key
              # @return [String] formatted message
              def call(offense)
                tags = Array(offense[:tags]).join(', ')
                "Documentation comment with #{tags} is orphaned - YARD will ignore it"
              end
            end
          end
        end
      end
    end
  end
end
