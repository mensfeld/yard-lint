# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module OptionTags
          # Parser for @option tag validation results
          class Parser < Parsers::Base
          # @param yard_output [String] raw yard output with option tag issues
          # @return [Array<Hash>] array with option tag violation details
            def call(yard_output)
              return [] if yard_output.nil? || yard_output.empty?

              lines = yard_output.split("\n").reject(&:empty?)
              results = []

              lines.each_slice(2) do |location_line, status_line|
                  next unless location_line && status_line
                  next unless status_line == 'missing_option_tags'

                  # Parse location line: "file.rb:10: ClassName#method_name"
                  match = location_line.match(/^(.+):(\d+): (.+)$/)
                  next unless match

                  file = match[1]
                  line = match[2].to_i
                  method_name = match[3]

                  results << {
                    name: 'MissingOptionTags',
                    method_name: method_name,
                    location: file,
                    line: line
                  }
                end

              results
            end
        end
        end
      end
    end
  end
end