# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InvalidTypes
          # Parser for invalid tag types output.
          # The validator emits two lines per offense:
          #   /path/to/file.rb:10: ClassName#method_name
          #   @tagname param_name:BadType1,BadType2|@tagname2:BadType3
          class Parser < Parsers::Base
            # @return [Regexp] matches "file:line: ClassName#method"
            LOCATION_REGEX = /^(.+):(\d+):\s+(.+)[#.](.+)$/
            # @return [Regexp] matches the tag violations line (starts with @)
            TAG_VIOLATIONS_REGEX = /^@/

            # @param yard_output [String] raw validator output
            # @return [Array<Hash>] parsed offenses
            def call(yard_output)
              lines = yard_output.split("\n").reject(&:empty?)
              results = []
              i = 0

              while i < lines.size
                match = lines[i].match(LOCATION_REGEX)

                unless match
                  i += 1
                  next
                end

                offense = {
                  location: match[1],
                  line: match[2].to_i,
                  class_name: match[3],
                  method_name: match[4],
                  tag_violations: []
                }

                next_line = lines[i + 1]
                if next_line&.match?(TAG_VIOLATIONS_REGEX)
                  offense[:tag_violations] = parse_tag_violations(next_line)
                  i += 2
                else
                  i += 1
                end

                results << offense
              end

              results
            end

            private

            # Parse "tagname param:Type1,Type2|tagname2:Type3" into structured data
            # @param line [String] the violations line
            # @return [Array<Hash>] each entry has :tag, :param (may be nil), :types
            def parse_tag_violations(line)
              line.split('|').map do |entry|
                label, types_str = entry.split(':', 2)
                parts = label.split(' ', 2)
                {
                  tag: parts[0],
                  param: parts[1],
                  types: (types_str || '').split(',').reject(&:empty?)
                }
              end
            end
          end
        end
      end
    end
  end
end
