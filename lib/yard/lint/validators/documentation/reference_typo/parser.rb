# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module ReferenceTypo
          # Parser for ReferenceTypo validator output
          class Parser < ::Yard::Lint::Parsers::Base
            # Parses validator output and extracts reference typo violations
            # Expected format (two lines per violation):
            #   file.rb:LINE: ObjectName
            #   reference|suggestion
            # @param yard_output [String] raw validator output
            # @return [Array<Hash>] array with violation details
            def call(yard_output, **)
              return [] if yard_output.nil? || yard_output.strip.empty?

              lines = yard_output.split("\n").map(&:strip).reject(&:empty?)

              lines.each_slice(2).filter_map do |location_line, details_line|
                next unless location_line && details_line

                location_match = location_line.match(/^(.+):(\d+): (.+)$/)
                next unless location_match

                reference, suggestion = details_line.split('|', 2)
                next if reference.to_s.empty? || suggestion.to_s.empty?

                {
                  location: location_match[1],
                  line: location_match[2].to_i,
                  object_name: location_match[3],
                  reference: reference,
                  suggestion: suggestion
                }
              end
            end
          end
        end
      end
    end
  end
end
