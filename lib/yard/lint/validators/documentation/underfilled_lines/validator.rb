# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UnderfilledLines
          # Detects documentation prose that wraps before using the available line width.
          #
          # Uses YARD's `docstring.line_range` to locate the exact source lines belonging
          # to the docstring block (mirroring {LineLength}), classifies each line as prose
          # or structural, groups contiguous prose into paragraphs, and reports a
          # paragraph when greedily re-wrapping it at `MaxLength` would use fewer lines.
          class Validator < Validators::Base
            in_process visibility: :all

            # Characters that may trail a sentence boundary char without changing the
            # fact that the line ends a clause (closing bracket/quote/backtick).
            TRAILING_CLOSERS = /[)\]"'`]+\z/

            # Execute query for a single object during in-process execution.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.file && File.exist?(object.file)
              return if object.docstring.all.empty?

              line_range = object.docstring.line_range
              return unless line_range
              return if duplicate_docstring?(object)

              max_length = config_or_default('MaxLength').to_i
              min_trailing = config_or_default('MinTrailingSpace').to_i
              min_lines = [config_or_default('MinParagraphLines').to_i, 2].max
              boundary = Array(config_or_default('SentenceEndChars'))
              skip_non_ascii = config_or_default('SkipNonAscii')

              source_lines = cached_lines(object.file)
              classified = classify_lines(line_range, source_lines, skip_non_ascii)

              violations = []
              group_paragraphs(classified).each do |paragraph|
                next if paragraph.size < min_lines
                next if ventilated?(paragraph, boundary)

                actual = paragraph.size
                reflowed = reflow_count(paragraph, max_length)
                next unless reflowed < actual

                widest = paragraph[0..-2].map { |line| line[:length] }.max
                next if (max_length - widest) < min_trailing

                violations << "#{paragraph.first[:line_no]}:#{actual}:#{reflowed}:#{widest}"
              end

              return if violations.empty?

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts "#{max_length}|#{violations.join('|')}"
            end

            private

            # Returns the lines of a source file, reading from disk only on the first
            # call for each unique path.
            # @param file [String] absolute path to the source file
            # @return [Array<String>] lines of the file, memoized per path
            def cached_lines(file)
              @file_cache ||= {}
              # scrub invalid bytes so the marker/structural regexes never raise
              # Encoding::CompatibilityError on a non-UTF-8 source file.
              @file_cache[file] ||= File.readlines(file).map!(&:scrub)
            end

            # Classify each source line in the docstring range. Plain-prose lines become
            # hashes; everything else (blank lines, tags, code, markdown structure) is a
            # `:break` marker that separates paragraphs.
            # @param line_range [Range] absolute source line numbers of the docstring
            # @param source_lines [Array<String>] raw lines of the source file
            # @param skip_non_ascii [Boolean] treat non-ASCII lines as structural
            # @return [Array<Hash, Symbol>] prose hashes interleaved with :break markers
            def classify_lines(line_range, source_lines, skip_non_ascii)
              base_indent = base_indent_for(line_range, source_lines)
              result = []
              in_fence = false
              in_tag_region = false

              line_range.each do |line_no|
                raw = source_lines[line_no - 1].to_s.rstrip
                marker = raw.match(/\A(\s*#+\s?)(.*)\z/)

                # Not a comment line (e.g. the definition itself, or a block comment body)
                unless marker
                  result << :break
                  in_tag_region = false
                  next
                end

                content = marker[2]
                stripped = content.strip

                # Fenced code block delimiters toggle the fence; the delimiter line and
                # everything inside it is structural.
                if stripped.start_with?('```', '~~~')
                  in_fence = !in_fence
                  result << :break
                  next
                end
                if in_fence
                  result << :break
                  next
                end

                if stripped.empty?
                  result << :break
                  in_tag_region = false
                  next
                end

                # A real YARD tag/directive begins at column 0 of the comment content.
                # It and its indented continuation lines are skipped; only the free-text
                # description body is checked.
                if content.start_with?('@')
                  in_tag_region = true
                  result << :break
                  next
                end
                if in_tag_region
                  if content.match?(/\A[ \t]/)
                    result << :break
                    next
                  end
                  in_tag_region = false
                end

                # Lines indented past the block's base indentation are code samples,
                # ASCII diagrams or nested list continuations - not flowing prose.
                indent = content.length - content.lstrip.length
                if indent > base_indent || structural_content?(stripped, skip_non_ascii)
                  result << :break
                  next
                end

                result << {
                  line_no: line_no,
                  prefix_width: raw.length - stripped.length,
                  content: stripped,
                  length: raw.length
                }
              end

              result
            end

            # The smallest content indentation among non-empty comment lines in the
            # range. Flowing prose sits at this base; anything deeper is treated as a
            # nested, code or diagram line.
            # @param line_range [Range] absolute source line numbers of the docstring
            # @param source_lines [Array<String>] raw lines of the source file
            # @return [Integer] base indentation in columns (0 for normal `# ` comments)
            def base_indent_for(line_range, source_lines)
              indents = []
              line_range.each do |line_no|
                raw = source_lines[line_no - 1].to_s.rstrip
                marker = raw.match(/\A(\s*#+\s?)(.*)\z/)
                next unless marker

                content = marker[2]
                next if content.strip.empty?

                indents << (content.length - content.lstrip.length)
              end
              indents.min || 0
            end

            # Whether a prose-looking comment line is actually structural and must not
            # take part in reflow (markdown, code, diagrams, RDoc directives, ...).
            # @param stripped [String] comment content, stripped of the marker and whitespace
            # @param skip_non_ascii [Boolean] treat non-ASCII content as structural
            # @return [Boolean]
            def structural_content?(stripped, skip_non_ascii)
              return true if skip_non_ascii && !stripped.ascii_only?
              # Markdown heading, blockquote
              return true if stripped.start_with?('#', '>')
              # Table row
              return true if stripped.include?('|')
              # List items (bulleted or ordered)
              return true if stripped.match?(/\A[-*+]\s/)
              return true if stripped.match?(/\A\d+[.)]\s/)
              # Thematic break (---, ***, ___)
              return true if stripped.match?(/\A([-*_])\1\1+\z/)
              # RDoc directives
              return true if stripped.match?(/\A:\w+:/)
              return true if stripped.end_with?(':nodoc:', ':doc:')
              # Intentional hard break / hyphenation
              return true if stripped.end_with?('-')
              # Column alignment (2+ internal spaces) or box-drawing diagrams
              return true if stripped.match?(/\S {2,}\S/)
              return true if stripped.match?(/[─-╿▀-▟]/)

              false
            end

            # Group the classified entries into paragraphs: maximal runs of contiguous
            # prose lines sharing the same comment-marker indentation.
            # @param classified [Array<Hash, Symbol>] output of {#classify_lines}
            # @return [Array<Array<Hash>>] paragraphs, each an array of prose line hashes
            def group_paragraphs(classified)
              paragraphs = []
              current = []

              flush = lambda do
                paragraphs << current unless current.empty?
                current = []
              end

              classified.each do |entry|
                if entry == :break
                  flush.call
                elsif current.empty? || current.last[:prefix_width] == entry[:prefix_width]
                  current << entry
                else
                  flush.call
                  current << entry
                end
              end
              flush.call

              paragraphs
            end

            # Whether a paragraph is deliberately broken one sentence/clause per line.
            # True when every non-final line ends at a sentence boundary character.
            # @param paragraph [Array<Hash>] prose line hashes
            # @param boundary [Array<String>] sentence-ending characters
            # @return [Boolean]
            def ventilated?(paragraph, boundary)
              return false if boundary.empty?

              paragraph[0..-2].all? do |line|
                last = line[:content].sub(TRAILING_CLOSERS, '')[-1]
                last && boundary.include?(last)
              end
            end

            # Number of lines the paragraph's words occupy when greedily wrapped at
            # `max_length`, using the paragraph's comment-marker prefix on every line.
            # A word that does not fit starts a new line, so breaks forced by an
            # unbreakable long token (URL, namespaced constant) are reproduced and do
            # not count as savings.
            # @param paragraph [Array<Hash>] prose line hashes
            # @param max_length [Integer] target width
            # @return [Integer] number of wrapped lines
            def reflow_count(paragraph, max_length)
              prefix_width = paragraph.first[:prefix_width]
              words = paragraph.flat_map { |line| line[:content].split }
              return paragraph.size if words.empty?

              lines = 1
              current = prefix_width + words.first.length
              words.drop(1).each do |word|
                if current + 1 + word.length <= max_length
                  current += 1 + word.length
                else
                  lines += 1
                  current = prefix_width + word.length
                end
              end
              lines
            end
          end
        end
      end
    end
  end
end
