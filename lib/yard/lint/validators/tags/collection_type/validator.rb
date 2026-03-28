# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module CollectionType
          # Validates Hash and Array collection type syntax in YARD tags
          class Validator < Base
            # Enable in-process execution
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Validates collection type syntax based on EnforcedStyle.
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
                  detected_style = detect_style(type_str)

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

            # Detects the collection style used in a type string
            # @param type_str [String] the type string to check
            # @return [String, nil] 'long' or 'short', or nil if not a collection type
            def detect_style(type_str)
              # Hash types
              # Hash<...> is short style (should be Hash{K => V})
              if type_str =~ /Hash<.*>/
                'short'
              # Hash{...} is long style
              elsif type_str =~ /Hash\{.*\}/
                'long'
              # {...} without Hash prefix is short style
              elsif type_str =~ /^\{.*\}$/
                'short'
              # Array types
              # Array<...> is long style
              elsif type_str =~ /Array<.*>/
                'long'
              # Array(...) is long style
              elsif type_str =~ /Array\(.*\)/
                'long'
              # <...> without Array prefix is short style
              elsif type_str =~ /^<.*>$/
                'short'
              # (...) without Array prefix is short style (tuple shorthand)
              elsif type_str =~ /^\(.*\)$/
                'short'
              end
            end

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
