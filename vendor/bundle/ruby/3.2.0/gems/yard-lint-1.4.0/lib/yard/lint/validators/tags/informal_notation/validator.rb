# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InformalNotation
          # Validates that documentation uses proper YARD tags instead of
          # informal notation patterns like "Note:", "TODO:", etc.
          class Validator < Base
            # Enable in-process execution with public visibility
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Checks for informal notation patterns in docstrings.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              docstring_text = object.docstring.to_s
              return if docstring_text.empty?

              patterns = config_patterns
              case_sensitive = config_case_sensitive
              require_start = config_require_start_of_line

              found_patterns = find_informal_patterns(
                docstring_text,
                patterns,
                case_sensitive,
                require_start
              )

              return if found_patterns.empty?

              # Output format: two lines per violation
              # Line 1: file:line: object_title
              # Line 2: pattern|replacement|line_offset|line_text (pipe-separated)
              found_patterns.each do |match|
                collector.puts "#{object.file}:#{object.line}: #{object.title}"
                collector.puts "#{match[:pattern]}|#{match[:replacement]}|" \
                               "#{match[:line_offset]}|#{match[:line_text]}"
              end
            end

            private

            # Find informal patterns in docstring text, skipping code blocks
            # @param docstring_text [String] the docstring text to scan
            # @param patterns [Hash] pattern => replacement mapping
            # @param case_sensitive [Boolean] whether to match case-sensitively
            # @param require_start [Boolean] whether pattern must be at start of line
            # @return [Array<Hash>] array of matches with pattern, replacement, line_offset, line_text
            def find_informal_patterns(docstring_text, patterns, case_sensitive, require_start)
              found_patterns = []
              matched_lines = Set.new
              in_code_block = false

              docstring_text.lines.each_with_index do |line, line_offset|
                # Track fenced code blocks (``` markers)
                if line.strip.start_with?('```')
                  in_code_block = !in_code_block
                  next
                end

                # Skip lines inside code blocks
                next if in_code_block

                # Skip lines already matched (avoids duplicate reports for similar patterns)
                next if matched_lines.include?(line_offset)

                patterns.each do |pattern, replacement|
                  next if replacement.nil? || replacement.empty?
                  next unless matches_pattern?(line, pattern, case_sensitive, require_start)

                  found_patterns << {
                    pattern: pattern,
                    replacement: replacement,
                    line_offset: line_offset,
                    line_text: line.strip
                  }
                  matched_lines.add(line_offset)
                  break
                end
              end

              found_patterns
            end

            # Check if a line matches the informal pattern
            # @param line [String] the line to check
            # @param pattern [String] the pattern to match (without colon)
            # @param case_sensitive [Boolean] whether to match case-sensitively
            # @param require_start [Boolean] whether pattern must be at start of line
            # @return [Boolean] true if the line matches
            def matches_pattern?(line, pattern, case_sensitive, require_start)
              # Build regex for pattern followed by colon
              escaped_pattern = Regexp.escape(pattern)

              regex_str = if require_start
                            # Match at start of line after optional whitespace
                            "^\\s*#{escaped_pattern}:"
                          else
                            # Match anywhere in line (after start or whitespace)
                            "(?:^|\\s)#{escaped_pattern}:"
                          end

              flags = case_sensitive ? nil : Regexp::IGNORECASE
              regex = Regexp.new(regex_str, flags)

              line.match?(regex)
            end

            # @return [Hash] configured patterns mapping informal -> YARD tag
            def config_patterns
              config_or_default('Patterns')
            end

            # @return [Boolean] whether matching should be case-sensitive
            def config_case_sensitive
              config_or_default('CaseSensitive')
            end

            # @return [Boolean] whether patterns must appear at start of line
            def config_require_start_of_line
              config_or_default('RequireStartOfLine')
            end
          end
        end
      end
    end
  end
end
