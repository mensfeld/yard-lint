# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module NonAsciiType
          # Parser for NonAsciiType validator output
          # Parses output that reports non-ASCII characters in type specifications
          class Parser < ::Yard::Lint::Parsers::Base
            # Parses validator output and extracts non-ASCII type violations
            # Expected format (two lines per violation):
            #   file.rb:LINE: ClassName#method_name
            #   tag_name|type_string|character|codepoint
            # @param yard_output [String] raw validator query results
            # @option _kwargs [Object] :unused this parameter accepts no options (reserved for future use)
            # @return [Array<Hash>] array with violation details
            def call(yard_output, **_kwargs)
              return [] if yard_output.nil?

              # Handle potential encoding issues
              sanitized = yard_output.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
              return [] if sanitized.strip.empty?

              lines = sanitized.split("\n").map(&:strip).reject(&:empty?)
              violations = []

              lines.each_slice(2) do |location_line, details_line|
                next unless location_line && details_line

                # Parse location: "file.rb:10: ClassName#method_name"
                location_match = location_line.match(/^(.+):(\d+): (.+)$/)
                next unless location_match

                # Parse details: "tag_name|type_string|character|codepoint"
                details = details_line.split('|', 4)
                next unless details.size == 4

                tag_name, type_string, character, codepoint = details

                violations << {
                  location: location_match[1],
                  line: location_match[2].to_i,
                  method_name: location_match[3],
                  tag_name: tag_name,
                  type_string: type_string,
                  character: character,
                  codepoint: codepoint
                }
              end

              violations
            end
          end
        end
      end
    end
  end
end
