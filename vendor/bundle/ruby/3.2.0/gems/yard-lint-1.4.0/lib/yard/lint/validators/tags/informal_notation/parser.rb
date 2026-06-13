# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InformalNotation
          # Parser for InformalNotation validator output
          # Parses YARD query output that reports informal notation violations
          class Parser < ::Yard::Lint::Parsers::Base
            # Parses YARD output and extracts informal notation violations
            # Expected format (two lines per violation):
            #   file.rb:LINE: ObjectName
            #   pattern|replacement|line_offset|line_text
            # @param yard_output [String] raw YARD query results
            # @option _kwargs [Object] :unused this parameter accepts no options (reserved for future use)
            # @return [Array<Hash>] array with violation details
            def call(yard_output, **_kwargs)
              return [] if yard_output.nil? || yard_output.strip.empty?

              lines = yard_output.split("\n").map(&:strip).reject(&:empty?)
              violations = []

              lines.each_slice(2) do |location_line, details_line|
                next unless location_line && details_line

                # Parse location: "file.rb:10: ObjectName"
                location_match = location_line.match(/^(.+):(\d+): (.+)$/)
                next unless location_match

                # Parse details: "pattern|replacement|line_offset|line_text"
                details = details_line.split('|', 4)
                next unless details.size >= 3

                pattern, replacement, line_offset_str, line_text = details

                violations << {
                  location: location_match[1],
                  line: location_match[2].to_i,
                  object_name: location_match[3],
                  pattern: pattern,
                  replacement: replacement,
                  line_offset: line_offset_str.to_i,
                  line_text: line_text || ''
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
