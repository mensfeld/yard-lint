# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TypeSyntax
          # Runs YARD to validate type syntax using TypesExplainer::Parser
          class Validator < Base
            # Enable in-process execution
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Validates type syntax in tags using YARD's TypesExplainer::Parser.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              validated_tags = config.validator_config('Tags/TypeSyntax', 'ValidatedTags') ||
                               %w[param option return yieldreturn]

              object.docstring.tags
                    .select { |tag| validated_tags.include?(tag.tag_name) }
                    .each do |tag|
                next unless tag.types

                tag.types.each do |type_str|
                  begin
                    YARD::Tags::TypesExplainer::Parser.parse(type_str)
                  rescue SyntaxError => e
                    collector.puts "#{object.file}:#{object.line}: #{object.title}"
                    collector.puts "#{tag.tag_name}|#{type_str}|#{e.message}"
                    break
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
