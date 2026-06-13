# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module NonAsciiType
          # Validates that type specifications contain only ASCII characters
          # Ruby type names must be valid Ruby identifiers (ASCII only)
          class Validator < Base
            # Enable in-process execution
            in_process visibility: :public

            # Pattern to match non-ASCII characters
            NON_ASCII_PATTERN = /[^\x00-\x7F]/

            # Execute query for a single object during in-process execution.
            # Checks type specifications for non-ASCII characters.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              validated_tags = config.validator_config('Tags/NonAsciiType', 'ValidatedTags') ||
                               %w[param option return yieldreturn yieldparam]

              object.docstring.tags
                    .select { |tag| validated_tags.include?(tag.tag_name) }
                    .each do |tag|
                next unless tag.types

                tag.types.each do |type_str|
                  non_ascii_chars = type_str.scan(NON_ASCII_PATTERN).uniq
                  next if non_ascii_chars.empty?

                  # Format: file:line: object_title
                  # Then: tag_name|type_string|char|codepoint
                  non_ascii_chars.each do |char|
                    codepoint = format('U+%04X', char.ord)
                    collector.puts "#{object.file}:#{object.line}: #{object.title}"
                    collector.puts "#{tag.tag_name}|#{type_str}|#{char}|#{codepoint}"
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
