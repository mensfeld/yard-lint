# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InvalidTypes
          # Parser for invalid tag types output.
          # The validator emits two lines per offense:
          #   /path/to/file.rb:10: ClassName#method_name
          #   @tagname param_name:BadType1,BadType2:Type|@tagname2:BadType3:Type2
          # One entry per type with invalid names. '%', '|', ',', ':' and newlines
          # inside tags, params, names and types are escaped as %25, %7C, %2C, %3A and %0A
          class Parser < Parsers::Base
            # @return [Regexp] matches "file:line: ObjectTitle"
            LOCATION_REGEX = /^(.+):(\d+):\s+(.+)$/
            # @return [Regexp] splits a title into namespace and method name on
            #   the last # or . separator; titles without one (e.g. CONST,
            #   Foo::Bar) are kept whole
            TITLE_REGEX = /\A(.*)[#.]([^#.]+)\z/
            # @return [Regexp] matches the tag violations line (starts with @)
            TAG_VIOLATIONS_REGEX = /^@/

            # @param yard_output [String] raw validator output
            # @return [Array<Hash>] parsed offenses
            def call(yard_output)
              lines = yard_output.split("\n").reject(&:empty?)
              results = []
              i = 0

              while i < lines.size
                # Violation lines (starting with @) must never be consumed as
                # location lines, even if they happen to match the loose regex
                match = lines[i].match?(TAG_VIOLATIONS_REGEX) ? nil : lines[i].match(LOCATION_REGEX)

                unless match
                  i += 1
                  next
                end

                class_name, method_name = split_title(match[3])

                offense = {
                  location: match[1],
                  line: match[2].to_i,
                  class_name: class_name,
                  method_name: method_name,
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

            # Splits a YARD object title into namespace and method name parts
            # @param title [String] object title (e.g. "Foo#bar", "#bar", "CONST")
            # @return [Array(String, String)] namespace and method name; for titles
            #   without a separator both parts are the full title
            def split_title(title)
              match = title.match(TITLE_REGEX)
              match ? [match[1], match[2]] : [title, title]
            end

            # Parse "tagname param:Bad1,Bad2:Type|tagname2:Bad3:Type2" into structured data
            # @param line [String] the violations line
            # @return [Array<Hash>] each entry has :tag, :param (may be nil), :types
            #   (the invalid names) and :type_string (the full type, may be nil)
            def parse_tag_violations(line)
              line.split('|').map do |entry|
                label, types_str, type_string = entry.split(':', 3)
                tag, param = label.split(' ', 2)
                {
                  tag: unescape_field(tag),
                  param: param && unescape_field(param),
                  types: (types_str || '').split(',').reject(&:empty?).map { |name| unescape_field(name) },
                  type_string: type_string && unescape_field(type_string)
                }
              end
            end

            # Reverts the validator's escaping
            # @param text [String] escaped field text
            # @return [String] raw field text
            def unescape_field(text)
              text.gsub(/%(?:25|7C|2C|3A|0A)/, '%25' => '%', '%7C' => '|', '%2C' => ',', '%3A' => ':', '%0A' => "\n")
            end
          end
        end
      end
    end
  end
end
