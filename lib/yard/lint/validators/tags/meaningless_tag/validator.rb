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

              # @param is meaningful on Struct.new / Data.define constants because
              # Solargraph uses those annotations to type the synthesized accessors.
              effective_tags = struct_or_data_class?(object) ? tags_to_check - ['param'] : tags_to_check
              return if effective_tags.empty?

              object.docstring.tags.each do |tag|
                next unless effective_tags.include?(tag.tag_name)

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

            # @param object [YARD::CodeObjects::Base] the code object to inspect
            # @return [Boolean] true when the object is a class synthesised by Struct.new
            #   or Data.define, where @param documents the generated accessors
            def struct_or_data_class?(object)
              return false unless object.type == :class

              sc_path = object.superclass&.path
              sc_path == 'Struct' || sc_path == 'Data'
            end
          end
        end
      end
    end
  end
end
