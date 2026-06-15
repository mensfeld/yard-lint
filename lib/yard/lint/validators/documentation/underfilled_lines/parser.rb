# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UnderfilledLines
          # Parses UnderfilledLines validator output into structured violation hashes.
          #
          # Expected format (two lines per object with violations):
          #   file.rb:OBJECT_LINE: ObjectName
          #   MAX_LENGTH|START:ACTUAL:REFLOW:WIDEST|START:ACTUAL:REFLOW:WIDEST|...
          class Parser < Parsers::Base
            # @param output [String] raw validator output
            # @return [Array<Hash>] array of violation hashes
            def call(output, **)
              return [] if output.nil? || output.empty?

              violations = []
              lines = output.lines.map(&:chomp)

              i = 0
              while i < lines.size
                location_match = lines[i].match(/^(.+):(\d+): (.+)$/)

                if location_match
                  file_path = location_match[1]
                  object_line = location_match[2].to_i
                  object_name = location_match[3]

                  i += 1
                  if i < lines.size
                    parts = lines[i].split('|')
                    max_length = parts.shift.to_i

                    parts.each do |part|
                      start, actual, reflow, widest = part.split(':', 4)
                      next unless start && actual && reflow && widest

                      violations << {
                        location: file_path,
                        line: start.to_i,
                        object_line: object_line,
                        object_name: object_name,
                        actual_lines: actual.to_i,
                        reflowed_lines: reflow.to_i,
                        widest_fill: widest.to_i,
                        max_length: max_length
                      }
                    end
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
