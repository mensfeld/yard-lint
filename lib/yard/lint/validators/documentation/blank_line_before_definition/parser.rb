# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module BlankLineBeforeDefinition
          # Parses YARD output for blank line before definition violations
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

                  # Parse violation: "single:1" or "orphaned:3"
                  detail_parts = lines[i].split(':', 2)
                  next unless detail_parts.size == 2

                  violation_type = detail_parts[0]
                  blank_count = detail_parts[1].to_i

                  violations << {
                    location: file_path,
                    line: object_line,
                    object_name: object_name,
                    violation_type: violation_type,
                    blank_count: blank_count
                  }
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
