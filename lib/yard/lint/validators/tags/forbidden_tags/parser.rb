# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ForbiddenTags
          # Parser for ForbiddenTags validator output
          # Parses in-process output that reports forbidden tag patterns
          class Parser < ::Yard::Lint::Parsers::Base
            # Parses validator output and extracts forbidden tag violations
            # Expected format (two lines per violation):
            #   file.rb:LINE: ObjectName
            #   tag_name|types_text|pattern_types
            # @param yard_output [String] raw validator output
            # @return [Array<Hash>] array with violation details
            def call(yard_output, **)
              return [] if yard_output.nil? || yard_output.strip.empty?

              lines = yard_output.split("\n").map(&:strip).reject(&:empty?)
              violations = []

              lines.each_slice(2) do |location_line, details_line|
                next unless location_line && details_line

                location_match = location_line.match(/^(.+):(\d+): (.+)$/)
                next unless location_match

                details = details_line.split('|', 3)
                next if details.empty?

                tag_name, types_text, pattern_types = details

                violations << {
                  location: location_match[1],
                  line: location_match[2].to_i,
                  object_name: location_match[3],
                  tag_name: tag_name,
                  types_text: types_text || '',
                  pattern_types: pattern_types || ''
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
