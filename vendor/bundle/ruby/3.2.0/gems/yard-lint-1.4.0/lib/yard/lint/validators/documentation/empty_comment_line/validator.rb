# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module EmptyCommentLine
          # Validates empty comment lines at the start/end of documentation blocks
          class Validator < Validators::Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Checks for empty leading/trailing comment lines in documentation blocks.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.file && File.exist?(object.file) && object.line.to_i > 1

              check_leading = check_leading?
              check_trailing = check_trailing?

              source_lines = File.readlines(object.file)
              definition_line = object.line - 1

              # Find comment block boundaries
              comment_end = nil
              comment_start = nil

              (definition_line - 1).downto(0) do |i|
                line = source_lines[i].to_s.rstrip
                stripped = line.strip

                if stripped.empty? && comment_end.nil?
                  # Skip empty lines before finding comment block
                  next
                elsif stripped.start_with?('#')
                  comment_end ||= i
                  comment_start = i
                else
                  break
                end
              end

              return unless comment_start && comment_end

              comment_block = source_lines[comment_start..comment_end]

              # Find first and last content lines
              first_content_idx = nil
              last_content_idx = nil

              comment_block.each_with_index do |line, idx|
                stripped = line.strip
                has_content = stripped.match?(/^#.+\S/)
                if has_content
                  first_content_idx ||= idx
                  last_content_idx = idx
                end
              end

              return unless first_content_idx && last_content_idx

              violations = []

              # Check for leading empty comment lines
              if check_leading
                (0...first_content_idx).each do |i|
                  if comment_block[i].strip.match?(/^#\s*$/)
                    violations << "leading:#{comment_start + i + 1}"
                  end
                end
              end

              # Check for trailing empty comment lines
              if check_trailing
                ((last_content_idx + 1)...comment_block.length).each do |i|
                  if comment_block[i].strip.match?(/^#\s*$/)
                    violations << "trailing:#{comment_start + i + 1}"
                  end
                end
              end

              return if violations.empty?

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts violations.join('|')
            end

            private

            # @return [Boolean] whether to check for leading empty lines
            def check_leading?
              patterns = config_or_default('EnabledPatterns')
              patterns['Leading']
            end

            # @return [Boolean] whether to check for trailing empty lines
            def check_trailing?
              patterns = config_or_default('EnabledPatterns')
              patterns['Trailing']
            end
          end
        end
      end
    end
  end
end
