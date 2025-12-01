# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagGroupSeparator
          # Parser for extracting tag group separator violations from raw validator output.
          #
          # @example Output format
          #   /path/to/file.rb:10: ClassName#method_name
          #   param->return,return->error
          class Parser < Parsers::Base
            # Regexp to extract only word and numeric parts of the location line
            NORMALIZATION_REGEXP = /\w+/

            private_constant :NORMALIZATION_REGEXP

            # Parses raw validator output into structured offense data.
            #
            # @param yard_list [String] raw validator output string
            #
            # @return [Array<Hash>] array of hashes with offense details
            def call(yard_list)
              return [] if yard_list.nil? || yard_list.empty?

              base_hash = {}

              yard_list.split("\n").each_slice(2).each do |location, separators|
                next if location.nil? || separators.nil?

                key = normalize(location)

                if separators == 'valid'
                  base_hash[key] = 'valid'
                else
                  base_hash[key] ||= [location, separators]
                end
              end

              base_hash.delete_if { |_key, value| value == 'valid' }
              separator_data = base_hash.values.map(&:last)

              Validators::Documentation::UndocumentedMethodArguments::Parser
                .new
                .call(base_hash.values.map(&:first).join("\n"))
                .each.with_index { |element, index| element[:separators] = separator_data[index] }
            end

            private

            # Normalizes a location line by extracting only word and numeric characters.
            #
            # @param location_line [String] full line with the location
            #
            # @return [String] normalized line without special characters
            def normalize(location_line)
              location_line
                .scan(NORMALIZATION_REGEXP)
                .join
            end
          end
        end
      end
    end
  end
end
