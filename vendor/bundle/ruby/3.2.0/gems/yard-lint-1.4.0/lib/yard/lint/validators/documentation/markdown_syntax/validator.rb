# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module MarkdownSyntax
          # Validates markdown syntax in documentation
          class Validator < Validators::Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Checks for markdown syntax errors in docstrings.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              docstring_text = object.docstring.to_s
              return if docstring_text.empty?

              errors = []

              # Check for unclosed backticks
              backtick_count = docstring_text.scan(/`/).count
              errors << 'unclosed_backtick' if backtick_count.odd?

              # Check for unclosed code blocks
              code_block_count = docstring_text.scan(/^```/).count
              errors << 'unclosed_code_block' if code_block_count.odd?

              # Check for unclosed bold markers (excluding code sections)
              non_code_text = docstring_text.gsub(/`[^`]*`/, '')
              bold_count = non_code_text.scan(/\*\*/).count
              errors << 'unclosed_bold' if bold_count.odd?

              # Check for invalid list markers
              docstring_text.lines.each_with_index do |line, line_idx|
                stripped = line.strip
                errors << "invalid_list_marker:#{line_idx + 1}" if stripped.match?(/^[•·]/)
              end

              return if errors.empty?

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts errors.join('|')
            end
          end
        end
      end
    end
  end
end
