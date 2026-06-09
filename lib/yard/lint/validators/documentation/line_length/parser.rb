# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module LineLength
          # Parses LineLength validator output into structured violation hashes.
          #
          # Expected format (two lines per object with violations):
          #   file.rb:OBJECT_LINE: ObjectName
          #   LINE_NO:LENGTH|LINE_NO:LENGTH|...
          class Parser < Parsers::Base
            # @param output [String] raw validator output
            # @return [Array<Hash>] array of violation hashes
            def call(output, **)
              return [] if output.nil? || output.empty?

              violations = []
              lines = output.lines.map(&:chomp)

              i = 0
              while i < lines.size
                line = lines[i]

                if (location_match = line.match(/^(.+):(\d+): (.+)$/))
                  file_path = location_match[1]
                  object_line = location_match[2].to_i
                  object_name = location_match[3]

                  i += 1
                  next unless i < lines.size

                  lines[i].split('|').each do |part|
                    line_no, length = part.split(':', 2)
                    next unless line_no && length

                    violations << {
                      location: file_path,
                      line: line_no.to_i,
                      object_line: object_line,
                      object_name: object_name,
                      length: length.to_i
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
