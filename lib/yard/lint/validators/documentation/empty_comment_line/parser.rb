# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module EmptyCommentLine
          # Parses YARD output for empty comment line violations
          class Parser < Parsers::Base
            # Parse YARD output into structured violations
            # @param output [String] raw YARD output
            # @return [Array<Hash>] array of violation hashes
            def call(output)
              return [] if output.nil? || output.empty?

              violations = []
              lines = output.lines.map(&:chomp)

              i = 0
              while i < lines.size
                line = lines[i]

                # Match location line: "file:line: object_name"
                if (location_match = line.match(/^(.+):(\d+): (.+)$/))
                  file_path = location_match[1]
                  object_line = location_match[2].to_i
                  object_name = location_match[3]

                  # Next line contains violation details
                  i += 1
                  next unless i < lines.size

                  # Parse violations: "leading:5|trailing:10"
                  violation_parts = lines[i].split('|')

                  violation_parts.each do |part|
                    type, line_num = part.split(':', 2)
                    next unless type && line_num

                    violations << {
                      location: file_path,
                      line: line_num.to_i,
                      object_line: object_line,
                      object_name: object_name,
                      violation_type: type
                    }
                  end
                end

                i += 1
              end

              violations
            end
          end
        end
      end
    end
  end
end
