# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Documentation validators - check for missing or incomplete documentation
      module Documentation
        module UndocumentedBooleanMethods
          # Class used to extract details about undocumented boolean methods
          # @example Output format (skip-lint)
          #   lib/platform/analysis/authors.rb:12: Platform::Analysis::Authors#valid?
          class Parser < Parsers::Base
            # Regex to extract file, line and method title from the validator output
            # Format: file.rb:LINE: Namespace#method?, Namespace.method?, or #method? and
            # ::method? at the root
            LINE_REGEX = /^(.+):(\d+): (.+)$/

            # Method name: the last segment of the title
            METHOD_NAME_REGEX = /[^#.:]+\z/

            # @param yard_list [String] raw yard list results string
            # @return [Array<Hash>] Array with undocumented boolean methods details
            def call(yard_list)
              yard_list
                .split("\n")
                .reject(&:empty?)
                .filter_map do |line|
                  match_data = line.match(LINE_REGEX)
                  next unless match_data

                  {
                    location: match_data[1],
                    line: match_data[2].to_i,
                    element: match_data[3],
                    method_name: match_data[3][METHOD_NAME_REGEX]
                  }
                end
            end
          end
        end
      end
    end
  end
end
