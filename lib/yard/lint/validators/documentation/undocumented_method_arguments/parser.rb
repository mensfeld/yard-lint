# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedMethodArguments
          # Class used to extract details about methods with undocumented arguments
        # @example
        #   Platform::Analysis::Authors#initialize
          class Parser < Parsers::Base
          # Regex to extract location and method name from yard list output
            LOCATION_REGEX = /^(.+)#(.+)$|^(.+)\.(.+)$/

          # @param yard_list [String] raw yard list results string
          # @return [Array<Hash>] Array with undocumented method arguments details
            def call(yard_list)
              yard_list
                .split("\n")
                .reject(&:empty?)
                .filter_map do |line|
                    match_data = line.match(LOCATION_REGEX)
                    next unless match_data

                    # Handle both instance (#) and class (.) methods
                    location = match_data[1] || match_data[3]
                    method_name = match_data[2] || match_data[4]

                    {
                      location: location,
                      method_name: method_name,
                      line: 0 # YARD list doesn't provide line numbers
                    }
                  end
              end
        end
        end
      end
    end
  end
end