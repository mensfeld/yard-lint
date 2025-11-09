# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module MeaninglessTag
          # Parser for MeaninglessTag validator output
          # Parses YARD query output that reports meaningless tags on non-methods
          class Parser < ::Yard::Lint::Parsers::Base
            # Parses YARD output and extracts meaningless tag violations
            # Expected format (two lines per violation):
            #   file.rb:LINE: ClassName
            #   object_type|tag_name
            # @param yard_output [String] raw YARD query results
            # @param _kwargs [Hash] unused keyword arguments (for compatibility)
            # @return [Array<Hash>] array with violation details
            def call(yard_output, **_kwargs)
              return [] if yard_output.nil? || yard_output.strip.empty?

              lines = yard_output.split("\n").map(&:strip).reject(&:empty?)
              violations = []

              lines.each_slice(2) do |location_line, details_line|
                next unless location_line && details_line

                # Parse location: "file.rb:10: ClassName"
                location_match = location_line.match(/^(.+):(\d+): (.+)$/)
                next unless location_match

                # Parse details: "object_type|tag_name"
                details = details_line.split('|', 2)
                next unless details.size == 2

                object_type, tag_name = details

                violations << {
                  location: location_match[1],
                  line: location_match[2].to_i,
                  object_name: location_match[3],
                  object_type: object_type,
                  tag_name: tag_name
                }
              end

              violations
            end
          end
        end
      end
    end
  end
end
