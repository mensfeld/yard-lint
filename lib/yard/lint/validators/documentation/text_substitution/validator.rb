# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module TextSubstitution
          # Validates that documentation does not contain forbidden strings.
          # Reports every matching substitution rule on every line independently.
          class Validator < Base
            in_process visibility: :public

            # @param object [YARD::CodeObjects::Base]
            # @param collector [Executor::ResultCollector]
            # @return [void]
            def in_process_query(object, collector)
              docstring_text = object.docstring.to_s
              return if docstring_text.empty?

              substitutions = config_or_default('Substitutions')
              return if substitutions.nil? || substitutions.empty?

              violations = find_violations(docstring_text, substitutions)
              return if violations.empty?

              violations.each do |violation|
                collector.puts "#{object.file}:#{object.line}: #{object.title}"
                collector.puts violation[:forbidden]
                collector.puts violation[:replacement]
                collector.puts "#{violation[:line_offset]}|#{violation[:line_text]}"
              end
            end

            private

            # Scans each line of a docstring for forbidden strings, skipping fenced code blocks.
            # @param docstring_text [String] full docstring text to scan
            # @param substitutions [Hash{String => String}] map of forbidden string to replacement
            # @return [Array<Hash>] list of violations with forbidden, replacement, line_offset, line_text
            def find_violations(docstring_text, substitutions)
              violations = []
              in_code_block = false

              docstring_text.lines.each_with_index do |line, line_offset|
                if line.strip.start_with?('```')
                  in_code_block = !in_code_block
                  next
                end
                next if in_code_block

                substitutions.each do |forbidden, replacement|
                  next if forbidden.nil? || forbidden.empty?
                  next if replacement.nil? || replacement.empty?
                  next unless line.include?(forbidden)

                  violations << {
                    forbidden: forbidden,
                    replacement: replacement,
                    line_offset: line_offset,
                    line_text: line.strip
                  }
                end
              end

              violations
            end
          end
        end
      end
    end
  end
end
