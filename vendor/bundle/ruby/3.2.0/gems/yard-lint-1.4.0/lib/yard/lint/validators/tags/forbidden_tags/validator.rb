# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ForbiddenTags
          # Validates that forbidden tag/type combinations are not used
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks for forbidden tag/type combinations in docstrings.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            def in_process_query(object, collector)
              patterns = forbidden_patterns
              return if patterns.empty?

              object.docstring.tags.each do |tag|
                patterns.each do |pattern|
                  next unless matches_pattern?(tag, pattern)

                  collector.puts "#{object.file}:#{object.line}: #{object.title}"
                  collector.puts build_details(tag, pattern)
                end
              end
            end

            private

            # @return [Array<Hash>] configured forbidden patterns
            def forbidden_patterns
              config_or_default('ForbiddenPatterns')
            end

            # Check if a tag matches a forbidden pattern
            # @param tag [YARD::Tags::Tag] the tag to check
            # @param pattern [Hash] the forbidden pattern with 'Tag' and optional 'Types'
            # @return [Boolean] true if tag matches the pattern
            def matches_pattern?(tag, pattern)
              return false unless tag.tag_name == pattern['Tag']

              pattern_types = pattern['Types']
              return true if pattern_types.nil? || pattern_types.empty?

              tag_types = tag.types || []
              (tag_types & pattern_types).any?
            end

            # Build details string for output
            # @param tag [YARD::Tags::Tag] the matched tag
            # @param pattern [Hash] the matched pattern
            # @return [String] details line for parser
            def build_details(tag, pattern)
              types_text = (tag.types || []).join(',')
              pattern_types = (pattern['Types'] || []).join(',')
              "#{tag.tag_name}|#{types_text}|#{pattern_types}"
            end
          end
        end
      end
    end
  end
end
