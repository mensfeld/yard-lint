# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module MissingYield
          # Parses validator output into structured offense hashes.
          # @example Output format (one offense per line)
          #   # "path/to/file.rb:10: ClassName#method_name"
          class Parser < ::Yard::Lint::Parsers::Base
            # @return [Regexp] parses "file:line: element" collector output lines
            LINE_REGEX = /^(.+):(\d+): (.+)$/.freeze

            # @param validator_output [String] raw collector output
            # @param config [Yard::Lint::Config, nil] configuration (unused)
            # @return [Array<Hash>] parsed offense hashes
            def call(validator_output, config: nil)
              validator_output
                .split("\n")
                .map(&:strip)
                .reject(&:empty?)
                .filter_map do |line|
                  match = line.match(LINE_REGEX)
                  next unless match

                  {
                    location: match[1],
                    line: match[2].to_i,
                    element: match[3]
                  }
                end
            end
          end
        end
      end
    end
  end
end
