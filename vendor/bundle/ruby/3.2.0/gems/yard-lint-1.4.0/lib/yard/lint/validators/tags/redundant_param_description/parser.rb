# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module RedundantParamDescription
          # Parses YARD output for redundant parameter description violations
          class Parser < Parsers::Base
            # Parse YARD output into structured violations
            # @param yard_output [String] raw YARD output
            # @return [Array<Hash>] array of violation hashes
            def call(yard_output)
              return [] if yard_output.nil? || yard_output.empty?

              violations = []
              lines = yard_output.lines.map(&:chomp)

              i = 0
              while i < lines.length
                line = lines[i]

                # Match location line: "file:line: object_name"
                location_match = line.match(/^(.+):(\d+): (.+)$/)
                unless location_match
                  i += 1
                  next
                end

                file_path = location_match[1]
                line_number = location_match[2].to_i
                object_name = location_match[3]

                # Next line contains violation data
                i += 1
                next unless i < lines.length

                data_line = lines[i]
                parts = data_line.split('|')
                next unless parts.length == 6

                tag_name, param_name, description, type_name, pattern_type, word_count = parts

                violations << {
                  name: 'RedundantParamDescription',
                  tag_name: tag_name,
                  param_name: param_name,
                  description: description,
                  type_name: type_name.empty? ? nil : type_name,
                  pattern_type: pattern_type,
                  word_count: word_count.to_i,
                  location: file_path,
                  line: line_number,
                  object_name: object_name
                }

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
