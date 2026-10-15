# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module OverloadConsistency
          # Parser for OverloadConsistency validator output
          class Parser < ::Yard::Lint::Parsers::Base
            # Offense kinds the validator emits
            KINDS = %w[unknown_param undocumented_param missing_return].freeze

            # Parses validator output and extracts overload violations
            # Expected format (two lines per violation):
            #   file.rb:LINE: ObjectName
            #   kind|param|signature
            # @param yard_output [String] raw validator output
            # @return [Array<Hash>] array with violation details
            def call(yard_output, **)
              return [] if yard_output.nil? || yard_output.strip.empty?

              lines = yard_output.split("\n").map(&:strip).reject(&:empty?)

              lines.each_slice(2).filter_map do |location_line, details_line|
                next unless location_line && details_line

                location_match = location_line.match(/^(.+):(\d+): (.+)$/)
                next unless location_match

                kind, param, signature = details_line.split('|', 3)
                next unless KINDS.include?(kind)
                next if signature.to_s.empty?

                {
                  location: location_match[1],
                  line: location_match[2].to_i,
                  object_name: location_match[3],
                  kind: kind,
                  param: param,
                  signature: signature
                }
              end
            end
          end
        end
      end
    end
  end
end
