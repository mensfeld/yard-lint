# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module OrphanedDocComment
          # Parses validator output into structured offense hashes.
          # @example Output format
          #   /path/to/file.rb:10: @param,@return
          class Parser < ::Yard::Lint::Parsers::Base
            LINE_REGEX = /^(.+):(\d+): ([@a-z,_]+)$/.freeze

            # @param validator_output [String] raw validator results string
            # @return [Array<Hash>] array of orphaned comment offense hashes
            def call(validator_output)
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
                    tags: match[3].split(',')
                  }
                end
            end
          end
        end
      end
    end
  end
end
