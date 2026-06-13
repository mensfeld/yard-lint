# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module MeaninglessTag
          # Validates that @param/@option tags only appear on methods
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks for @param/@option tags on non-method objects.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              object_type = object.type.to_s
              invalid_types = invalid_object_types
              tags_to_check = checked_tags

              return unless invalid_types.include?(object_type)

              object.docstring.tags.each do |tag|
                next unless tags_to_check.include?(tag.tag_name)

                collector.puts "#{object.file}:#{object.line}: #{object.title}"
                collector.puts "#{object_type}|#{tag.tag_name}"
                break
              end
            end

            private

            # @return [Array<String>] tags that should only appear on methods
            def checked_tags
              config_or_default('CheckedTags')
            end

            # @return [Array<String>] object types that shouldn't have method-only tags
            def invalid_object_types
              config_or_default('InvalidObjectTypes')
            end
          end
        end
      end
    end
  end
end
