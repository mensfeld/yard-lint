# frozen_string_literal: true

module Yard
  module Lint
    module Parsers
      # Class used to extract warnings details that are related to yard invalid tags order
      class InvalidTagsOrder < Base
        # Regexp to extract only word and numeric parts of the location line
        NORMALIZATION_REGEXP = /\w+/

        private_constant :NORMALIZATION_REGEXP

        # @param yard_list [Hash] hash with :result key containing raw yard list results string
        #   and :tags_order key with expected tags order
        # @return [Array<Hash>] hashes with details about objects with docs with invalid tags
        #   order.
        def call(yard_list)
          # Return empty array if yard_list is nil or empty
          return [] if yard_list.nil? || yard_list.empty?
          return [] if yard_list[:result].nil? || yard_list[:result].empty?

          # Each raw offense result is combined out of two lines:
          #   - first line contains the issue location
          #   - second the order in which the tags should be
          # That's why we split it and then for building the locations hashes we can use the
          #   UndocumentedMethodArguments parser as the location format is the same for both
          #   raw inputs
          base_hash = {}

          yard_list[:result].split("\n").each_slice(2).each do |location, ordering|
            key = normalize(location)

            if ordering == 'valid'
              base_hash[key] = 'valid'
            else
              base_hash[key] ||= [location, ordering]
            end
          end

          base_hash.delete_if { |_key, value| value == 'valid' }
          order = base_hash.values.map(&:last)

          UndocumentedMethodArguments.new
            .call(base_hash.values.map(&:first).join("\n"))
            .each.with_index { |element, index| element[:order] = order[index] }
        end

        private

        # @param location_line [String] full line with the location. It can be used, when we
        #   use module_function or other aliases that alter the yard tags order
        # @return [String] line without special characters
        def normalize(location_line)
          location_line
            .scan(NORMALIZATION_REGEXP)
            .join
        end
      end
    end
  end
end
