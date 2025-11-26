# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module CollectionType
          # Validates Hash collection type syntax in YARD tags
          class Validator < Base
            # Enable in-process execution
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Validates Hash collection type syntax based on EnforcedStyle.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              validated_tags = config_or_default('ValidatedTags')
              style = enforced_style

              object.docstring.tags
                    .select { |tag| validated_tags.include?(tag.tag_name) }
                    .each do |tag|
                next unless tag.types

                tag.types.each do |type_str|
                  detected_style = nil

                  # Check for Hash<...> syntax (angle brackets)
                  if type_str =~ /Hash<.*>/
                    detected_style = 'short'
                  # Check for Hash{...} syntax (curly braces)
                  elsif type_str =~ /Hash\{.*\}/
                    detected_style = 'long'
                  # Check for {...} syntax without Hash prefix
                  elsif type_str =~ /^\{.*\}$/
                    detected_style = 'short'
                  end

                  # Report violations based on enforced style
                  if detected_style && detected_style != style
                    collector.puts "#{object.file}:#{object.line}: #{object.title}"
                    collector.puts "#{tag.tag_name}|#{type_str}|#{detected_style}"
                    break
                  end
                end
              end
            end

            private

            # Gets the enforced collection style from configuration
            # @return [String] 'long' or 'short'
            def enforced_style
              config_or_default('EnforcedStyle')
            end
          end
        end
      end
    end
  end
end
