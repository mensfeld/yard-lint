# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module MeaninglessTag
          # Builds human-readable messages for MeaninglessTag violations
          class MessagesBuilder
            class << self
              # Formats a meaningless tag violation message
              # @param offense [Hash] offense details with :object_type, :tag_name, :object_name
              # @return [String] formatted message
              def call(offense)
                object_type = offense[:object_type]
                tag_name = offense[:tag_name]
                object_name = offense[:object_name]

                "The @#{tag_name} tag is meaningless on a #{object_type} " \
                  "(#{object_name}). This tag only makes sense on methods."
              end
            end
          end
        end
      end
    end
  end
end
