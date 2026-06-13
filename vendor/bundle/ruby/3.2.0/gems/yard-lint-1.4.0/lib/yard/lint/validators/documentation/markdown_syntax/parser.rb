# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module MarkdownSyntax
          # Parses YARD output for markdown syntax violations
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
                  line_number = location_match[2].to_i
                  object_name = location_match[3]

                  # Next line contains error types
                  i += 1
                  next unless i < lines.size

                  errors = lines[i].split('|')

                  violations << {
                    location: file_path,
                    line: line_number,
                    object_name: object_name,
                    errors: errors
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
