# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleSyntax
          # Parser for @example syntax validation results
          class Parser < Parsers::Base
            # @param yard_output [String] raw yard output with example syntax issues
            # @return [Array<Hash>] array with example syntax violation details
            def call(yard_output)
              return [] if yard_output.nil? || yard_output.empty?

              lines = yard_output.split("\n").reject(&:empty?)
              results = []

              # Output format is variable lines per error:
              # 1. file.rb:10: ClassName#method_name
              # 2. syntax_error
              # 3. Example name
              # 4+. Error message (can be multiple lines)
              # Next error starts with another file.rb:line: pattern

              i = 0
              while i < lines.length
                location_line = lines[i]

                # Parse location line: "file.rb:10: ClassName#method_name"
                # File paths typically start with a letter or . or / or ~
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
                status_line = lines[i]
                next unless status_line == 'syntax_error'

                # Next line is example name
                i += 1
                example_name = lines[i]

                # Collect all remaining lines until we hit the next location line or end
                error_message_lines = []
                i += 1
                while i < lines.length
                  # Check if this line starts a new error (matches file:line: pattern)
                  # File paths typically start with a letter or . or / or ~
                  break if lines[i].match?(%r{^[a-zA-Z./~].+:\d+: .+$})

                  error_message_lines << lines[i]
                  i += 1
                end

                results << {
                  name: 'ExampleSyntax',
                  object_name: object_name,
                  example_name: example_name,
                  error_message: error_message_lines.join("\n"),
                  location: file,
                  line: line
                }
              end

              results
            end
          end
        end
      end
    end
  end
end
