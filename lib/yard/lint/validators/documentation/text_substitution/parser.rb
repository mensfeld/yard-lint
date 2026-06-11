# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module TextSubstitution
          # Parses TextSubstitution validator output into structured violation hashes.
          #
          # Wire format (two lines per violation):
          #   file.rb:LINE: ObjectTitle
          #   forbidden|replacement|line_offset|line_text
          class Parser < ::Yard::Lint::Parsers::Base
            # @param yard_output [String] raw collector output from the validator
            # @option _kwargs [Object] :unused accepts no options (reserved for future use)
            # @return [Array<Hash>] array with violation details
            def call(yard_output, **_kwargs)
              return [] if yard_output.nil? || yard_output.strip.empty?

              lines = yard_output.split("\n").map(&:strip).reject(&:empty?)
              violations = []

              lines.each_slice(2) do |location_line, details_line|
                next unless location_line && details_line

                location_match = location_line.match(/^(.+):(\d+): (.+)$/)
                next unless location_match

                # Limit to 4 parts so line_text may contain pipe characters
                details = details_line.split('|', 4)
                next unless details.size >= 3

                forbidden, replacement, line_offset_str, line_text = details

                violations << {
                  location:    location_match[1],
                  line:        location_match[2].to_i,
                  object_name: location_match[3],
                  forbidden:   forbidden,
                  replacement: replacement,
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
