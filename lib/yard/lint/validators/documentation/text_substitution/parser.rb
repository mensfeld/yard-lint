# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module TextSubstitution
          # Parses TextSubstitution validator output into structured violation hashes.
          #
          # Wire format (four lines per violation):
          #   file.rb:LINE: ObjectTitle
          #   forbidden
          #   replacement
          #   line_offset|line_text
          #
          # forbidden and replacement occupy their own lines so they may contain
          # any character, including the pipe delimiter used in the last field.
          class Parser < ::Yard::Lint::Parsers::Base
            # @param yard_output [String] raw collector output from the validator
            # @option _kwargs [Object] :unused accepts no options (reserved for future use)
            # @return [Array<Hash>] array with violation details
            def call(yard_output, **_kwargs)
              return [] if yard_output.nil? || yard_output.strip.empty?

              # Do not strip lines — forbidden/replacement may have significant whitespace
              lines = yard_output.split("\n")
              violations = []

              lines.each_slice(4) do |location_line, forbidden_line, replacement_line, details_line|
                next unless location_line && forbidden_line && replacement_line && details_line

                location_match = location_line.strip.match(/^(.+):(\d+): (.+)$/)
                next unless location_match

                # line_offset is always numeric; split on first pipe only so line_text may contain pipes
                line_offset_str, line_text = details_line.split('|', 2)
                next unless line_offset_str

                violations << {
                  location:    location_match[1],
                  line:        location_match[2].to_i,
                  object_name: location_match[3],
                  forbidden:   forbidden_line,
                  replacement: replacement_line,
                  line_offset: line_offset_str.to_i,
                  line_text:   line_text || ''
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
