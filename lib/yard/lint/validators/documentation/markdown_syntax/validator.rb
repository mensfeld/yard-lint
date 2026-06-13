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
              return if duplicate_docstring?(object)

              errors = []

              # Check for unclosed inline backticks, ignoring fenced code blocks
              # (``` ... ```): their fence characters and contents are not
              # inline-code markers and otherwise inflate the count.
              errors << 'unclosed_backtick' if inline_backtick_count(docstring_text).odd?

              # Check for unclosed code blocks
              code_block_count = docstring_text.scan(/^```/).count
              errors << 'unclosed_code_block' if code_block_count.odd?

              # Check for unclosed bold markers, ignoring fenced code blocks and
              # inline code spans (their contents are code, not markdown) as well
              # as `**` runs surrounded by whitespace, which cannot delimit
              # CommonMark emphasis (e.g. the exponent operator in `x ** y`).
              errors << 'unclosed_bold' if bold_marker_count(docstring_text).odd?

              # Check for invalid list markers, reported with their absolute
              # source line rather than a docstring-relative index
              docstring_text.lines.each_with_index do |line, line_idx|
                stripped = line.strip
                errors << "invalid_list_marker:#{docstring_line(object, line_idx)}" if stripped.match?(/^[•·]/)
              end

              return if errors.empty?

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts errors.join('|')
            end

            private

            # Counts inline backticks, skipping fenced code blocks (``` ... ```)
            # entirely - their fence characters and contents are not inline-code
            # markers.
            # @param text [String] the docstring text
            # @return [Integer] number of inline backticks outside fenced blocks
            def inline_backtick_count(text)
              in_fence = false
              count = 0
              text.each_line do |line|
                if line.strip.start_with?('```')
                  in_fence = !in_fence
                  next
                end
                next if in_fence

                count += line.count('`')
              end
              count
            end

            # Counts `**` emphasis markers, skipping fenced code blocks and
            # inline code spans entirely. A `**` run is only counted when it
            # abuts a non-whitespace character on at least one side, since a run
            # padded by whitespace on both sides can neither open nor close
            # CommonMark emphasis - this excludes the exponent operator (`x ** y`)
            # without dropping genuine `**bold**` markers.
            # @param text [String] the docstring text
            # @return [Integer] number of bold markers that can delimit emphasis
            def bold_marker_count(text)
              in_fence = false
              count = 0
              text.each_line do |line|
                if line.strip.start_with?('```')
                  in_fence = !in_fence
                  next
                end
                next if in_fence

                non_code = line.gsub(/`[^`]*`/, '')
                non_code.scan(/(.?)\*\*(.?)/) do
                  before = Regexp.last_match(1)
                  after = Regexp.last_match(2)
                  count += 1 if before.match?(/\S/) || after.match?(/\S/)
                end
              end
              count
            end
          end
        end
      end
    end
  end
end
