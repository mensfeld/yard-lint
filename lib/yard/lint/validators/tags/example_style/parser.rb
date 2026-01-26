# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleStyle
          # Parser for @example style validation results
          class Parser < Parsers::Base
            # @param yard_output [String] raw yard output with example style issues
            # @return [Array<Hash>] array with example style violation details
            def call(yard_output)
              return [] if yard_output.nil? || yard_output.empty?

              # Normalize line endings (handle Windows \r\n)
              normalized_output = yard_output.gsub("\r\n", "\n")
              lines = normalized_output.split("\n").reject(&:empty?)
              results = []

              # Output format is exactly 5 lines per offense:
              # 1. file.rb:10: ClassName#method_name
              # 2. style_offense
              # 3. Example name
              # 4. Cop name (e.g., Style/StringLiterals)
              # 5. Offense message
              # Next offense starts with another file.rb:line: pattern

              i = 0
              while i < lines.length
                location_line = lines[i]

                # Parse location line: "file.rb:10: ClassName#method_name"
                match = location_line.match(%r{^([a-zA-Z./~].+):(\d+): (.+)$})
                unless match
                  i += 1
                  next
                end

                file = match[1]
                line = match[2].to_i
                object_name = match[3]

                # Next line should be status
                i += 1
                break if i >= lines.length

                status_line = lines[i]
                next unless status_line == 'style_offense'

                # Next line is example name
                i += 1
                break if i >= lines.length

                example_name = lines[i]

                # Next line is cop name
                i += 1
                break if i >= lines.length

                cop_name = lines[i]

                # Next line is message
                i += 1
                break if i >= lines.length

                message = lines[i]

                results << {
                  name: 'ExampleStyle',
                  object_name: object_name,
                  example_name: example_name,
                  cop_name: cop_name,
                  message: message,
                  location: file,
                  line: line
                }

                i += 1
              end

              results
            end
          end
        end
      end
    end
  end
end
