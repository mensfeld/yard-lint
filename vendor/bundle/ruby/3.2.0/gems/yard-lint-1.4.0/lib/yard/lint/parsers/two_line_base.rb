# frozen_string_literal: true

module Yard
  module Lint
    module Parsers
      # Base class for all two line warnings parsers
      class TwoLineBase < Base
        # @param yard_stats [String] raw yard stats results string
        # @return [Array<Hash>] array with all warnings informations from yard stats analysis
        def call(yard_stats)
          # Not all the lines from the yard_stats output are valuable, that's why we filter
          # them out, preprocess and leave only those against which we should match
          rows = classify(yard_stats.split("\n"))

          rows.map do |warning|
            {
              name: self.class.to_s.split('::').last,
              message: match(warning[0], :message).last,
              location: match(warning[1], :location).last,
              line: match(warning[1], :line).last.to_i
            }
          end
        end

        private

        # @param rows [Array<String>] array with lines of output from yard stats
        # @return [Array<Array<String>>] Array with always two elements - row that was
        #   classified and the next one because yard returns valuable chunks of informations
        #   in two lines that are one after another
        def classify(rows)
          buffor = []

          rows.each.with_index do |row, index|
            next unless row.match? self.class.regexps[:general]

            buffor << [rows[index].to_s, rows[index + 1].to_s]
          end

          buffor
        end
      end
    end
  end
end
