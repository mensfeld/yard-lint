# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedMethodArguments
          # Class used to extract details about methods with undocumented arguments
          # @example Output format (skip-lint)
          #   /path/to/file.rb:10: Platform::Analysis::Authors#initialize
          class Parser < Parsers::Base
            # Regex to extract file, line, and method name from yard list output
            # Format: /path/to/file.rb:10: ClassName#method_name
            LOCATION_REGEX = /^(.+):(\d+):\s+(.+)[#.](.+)$/

            # @param yard_list [String] raw yard list results string
            # @return [Array<Hash>] Array with undocumented method arguments details
            def call(yard_list)
              yard_list
                .split("\n")
                .reject(&:empty?)
                .filter_map do |line|
                  match_data = line.match(LOCATION_REGEX)
                  next unless match_data

                  # Extract: file path, line number, class name, method name
                  file_path = match_data[1]
                  line_number = match_data[2].to_i
                  class_name = match_data[3]
                  method_name = match_data[4]

                  {
                    location: file_path,
                    method_name: method_name,
                    line: line_number,
                    class_name: class_name
                  }
                end
            end
          end
        end
      end
    end
  end
end
