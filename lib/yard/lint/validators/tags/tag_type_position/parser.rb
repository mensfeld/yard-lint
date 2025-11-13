# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagTypePosition
          # Parses YARD output for TagTypePosition violations
          class Parser < ::Yard::Lint::Parsers::Base
            # Parses YARD query output into structured violation data
            # @param yard_output [String] raw output from YARD query
            # @option _kwargs [Object] :unused this parameter accepts no options (reserved for future use)
            # @return [Array<Hash>] array of violation hashes
            def call(yard_output, **_kwargs)
              return [] if yard_output.nil? || yard_output.strip.empty?

              lines = yard_output.split("\n").map(&:strip).reject(&:empty?)
              violations = []

              lines.each_slice(2) do |location_line, details_line|
                next unless location_line && details_line

                # Parse location: "file.rb:10: ClassName#method_name"
                location_match = location_line.match(/^(.+):(\d+): (.+)$/)
                next unless location_match

                # Parse details: "tag_name|param_name|type_info|detected_style"
                details = details_line.split('|', 4)
                next unless details.size >= 3

                tag_name, param_name, type_info, detected_style = details

                violations << {
                  location: location_match[1],
                  line: location_match[2].to_i,
                  object_name: location_match[3],
                  tag_name: tag_name,
                  param_name: param_name,
                  type_info: type_info,
                  detected_style: detected_style
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
