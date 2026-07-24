# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module BlankLineBeforeDefinition
          # Validates blank lines between documentation and definitions
          class Validator < Validators::Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Checks for blank lines between documentation blocks and definitions.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.file && File.exist?(object.file) && object.line.to_i > 1

              source_lines = File.readlines(object.file)
              definition_line = object.line - 1

              blank_count, doc_block_line = analyze_spacing(source_lines, definition_line)

              return if blank_count.zero? || doc_block_line.nil?

              # Only a comment block that is genuinely THIS object's documentation can have
              # been detached from it by the blank line. When the object is documented (its
              # docstring is non-empty) but that docstring did not come from the comment block
              # sitting above this definition, the block is a foreign comment - a file-level
              # license/copyright banner, an encoding note, or an unrelated comment above a
              # namespace reopening that is documented in another file - and the blank line is
              # intentional. This is decided by comparing the object's docstring against the
              # block's text, so it covers any such banner without hardcoding its wording.
              return if foreign_comment_block?(object, source_lines, doc_block_line)

              violation_type = blank_count >= 2 ? 'orphaned' : 'single'

              return unless pattern_enabled?(violation_type)

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts "#{violation_type}:#{blank_count}"
            end

            private

            # Analyze spacing between documentation and definition
            # @param source_lines [Array<String>] lines of source file
            # @param definition_line [Integer] 0-indexed line of definition
            # @return [Array<Integer, Integer, nil>] blank count and the 0-indexed line of the
            #   nearest documentation comment above the definition (nil when there is none)
            def analyze_spacing(source_lines, definition_line)
              blank_count = 0

              (definition_line - 1).downto(0) do |i|
                line = source_lines[i].to_s.rstrip
                stripped = line.strip

                if stripped.empty?
                  blank_count += 1
                elsif stripped.start_with?('#')
                  # Skip lines that are not YARD documentation: magic comments,
                  # shebangs, tool sigils/directives (Sorbet, RuboCop, Standard),
                  # and bare `#` separators. Treating them as a doc block caused
                  # spurious blank-line offenses for undocumented definitions.
                  next if non_documentation_comment?(stripped)

                  return [blank_count, i]
                else
                  # Non-comment, non-blank line - no documentation above
                  break
                end
              end

              [blank_count, nil]
            end

            # Whether the comment block above the definition is NOT the source of the object's
            # documentation - a file banner or an unrelated comment rather than a docstring
            # this definition lost to the blank line.
            #
            # An object with no docstring at all has genuinely orphaned documentation, so the
            # block above is still reported. When the object IS documented, the block only
            # counts as detached documentation if the docstring's text actually came from it;
            # a license header or a comment above a reopening documented elsewhere carries
            # different text and is left alone.
            # @param object [YARD::CodeObjects::Base] the code object being checked
            # @param source_lines [Array<String>] lines of source file
            # @param doc_line [Integer] 0-indexed line of the nearest comment above the definition
            # @return [Boolean]
            def foreign_comment_block?(object, source_lines, doc_line)
              docstring = object.docstring.to_s.strip
              return false if docstring.empty?

              block = comment_block_text(source_lines, doc_line)
              first_line = normalize(docstring.lines.first.to_s)
              return false if first_line.empty?

              !normalize(block).include?(first_line)
            end

            # Text of the contiguous comment block that contains `doc_line`, stripped of the
            # comment markers and joined into a single string.
            # @param source_lines [Array<String>] lines of source file
            # @param doc_line [Integer] 0-indexed line within the comment block
            # @return [String]
            def comment_block_text(source_lines, doc_line)
              first = doc_line
              first -= 1 while first.positive? && comment_line?(source_lines[first - 1])
              last = doc_line
              last += 1 while last + 1 < source_lines.length && comment_line?(source_lines[last + 1])

              source_lines[first..last].map { |line| line.sub(/\A\s*#+\s?/, '').strip }.join(' ')
            end

            # @param line [String, nil] a source line
            # @return [Boolean] whether the line is a comment line
            def comment_line?(line)
              line.to_s.strip.start_with?('#')
            end

            # Collapse whitespace so wrapped docstrings and their source comments compare equal.
            # @param text [String]
            # @return [String]
            def normalize(text)
              text.strip.gsub(/\s+/, ' ')
            end

            # Check if a comment line is a Ruby magic comment
            # @param line [String] stripped comment line
            # @return [Boolean] true if line is a magic comment
            def magic_comment?(line)
              # Ruby magic comments: frozen_string_literal, encoding, warn_indent, shareable_constant_value
              line.match?(/^#\s*(frozen[_-]string[_-]literal|encoding|warn[_-]indent|shareable[_-]constant[_-]value)\s*:/i)
            end

            # Check if a comment line is not YARD documentation (magic comment,
            # shebang, tool sigil/directive, or a bare `#` separator).
            # @param line [String] stripped comment line
            # @return [Boolean] true if the line should not count as documentation
            def non_documentation_comment?(line)
              magic_comment?(line) ||
                line.start_with?('#!') ||                          # shebang
                line.match?(/\A#\s*(rubocop|standard):/i) ||       # linter directives
                line.match?(/\A#\s*typed:/i) ||                    # Sorbet sigil
                line.match?(/\A#+\s*\z/)                           # bare # separator
            end

            # Check if the given pattern is enabled in configuration
            # @param violation_type [String] 'single' or 'orphaned'
            # @return [Boolean] whether the pattern is enabled
            def pattern_enabled?(violation_type)
              patterns = config_or_default('EnabledPatterns')
              case violation_type
              when 'single'
                patterns['SingleBlankLine']
              when 'orphaned'
                patterns['OrphanedDocs']
              else
                true
              end
            end
          end
        end
      end
    end
  end
end
