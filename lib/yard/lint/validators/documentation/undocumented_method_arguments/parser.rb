# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedMethodArguments
          # Class used to extract details about methods with undocumented arguments
          # Tags/Order and the separator validators reuse it for plain location
          # lines, which carry no tab-separated list of missing parameter names.
          # Names in that list are escaped as %25, %2C, %09 and %0A.
          # @example Output format (skip-lint)
          #   /path/to/file.rb:10: Platform::Analysis::Authors#initialize\tname,options
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
                  title = match_data[3]
                  title, _, missing = title.partition("\t") if title.include?("\t")
                  class_name, method_name = split_title(title)

                  offense = {
                    location: file_path,
                    method_name: method_name,
                    line: line_number,
                    class_name: class_name
                  }
                  next offense unless missing

                  offense[:element] = title
                  offense[:missing_params] = missing.split(',').map! { |name| unescape_field(name) }
                  offense
                end
            end

            private

            # Reverses the validator's escaping of '%', ',', tabs and newlines
            # @param text [String] escaped field text
            # @return [String] original text
            def unescape_field(text)
              return text unless text.include?('%')

              text.gsub(/%(?:25|2C|09|0A)/, '%25' => '%', '%2C' => ',', '%09' => "\t", '%0A' => "\n")
            end

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
