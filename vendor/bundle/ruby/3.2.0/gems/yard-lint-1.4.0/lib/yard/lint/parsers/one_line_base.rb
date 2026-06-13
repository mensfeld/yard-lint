# frozen_string_literal: true

module Yard
  module Lint
    module Parsers
      # Base class for all one line warnings parsers
      class OneLineBase < Base
        # @param yard_stats [String] raw yard stats results string
        # @return [Array<Hash>] array with all warnings informations from yard stats analysis
        def call(yard_stats)
          # Not all the lines from the yard_stats output are valuable, that's why we filter
          # them out, preprocess and leave only those against which we should match
          rows = classify(yard_stats.split("\n"))

          rows.map do |warning|
            {
              name: self.class.to_s.split('::').last,
              message: match(warning, :message).last,
              location: match(warning, :location).last,
              line: match(warning, :line).last.to_i
            }
          end
        end

        private

        # @param rows [Array<String>] array with lines of output from yard stats
        # @return [Array<String>] Array with rows that match the pattern
        def classify(rows)
          rows.grep(self.class.regexps[:general])
        end
      end
    end
  end
end
