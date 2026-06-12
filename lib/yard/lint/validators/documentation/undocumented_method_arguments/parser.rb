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
            # Regex to extract file, line, and object title from yard list output
            # Format: /path/to/file.rb:10: ClassName#method_name
            LOCATION_REGEX = /^(.+):(\d+):\s+(.+)$/
            # Splits an object title into namespace and method name on the last
            # # or . separator. Top-level methods (#foo) have an empty namespace;
            # titles without a separator (e.g. Foo::Bar, CONST) are kept whole.
            TITLE_REGEX = /\A(.*)[#.]([^#.]+)\z/

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
                  class_name, method_name = split_title(match_data[3])

                  {
                    location: file_path,
                    method_name: method_name,
                    line: line_number,
                    class_name: class_name
                  }
                end
            end

            private

            # Splits a YARD object title into namespace and method name parts
            # @param title [String] object title (e.g. "Foo#bar", "#bar", "CONST")
            # @return [Array(String, String)] namespace and method name; for titles
            #   without a separator both parts are the full title
            def split_title(title)
              match = title.match(TITLE_REGEX)
              match ? [match[1], match[2]] : [title, title]
            end
          end
        end
      end
    end
  end
end
