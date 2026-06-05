# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module OrphanedDocComment
          # Scans source files for YARD-tagged comment blocks that YARD will silently drop.
          # A comment block is orphaned when it has YARD tags but is immediately followed
          # by a non-documentable statement or sits at end-of-file.
          class Validator < Base
            in_process visibility: :public

            # Derive known tag names from YARD's own registry so we stay in sync with
            # any tags added by YARD plugins. This avoids false positives from instance
            # variable mentions in comments (e.g. `# @body.each` or `# @result is nil`).
            YARD_TAG_PATTERN = begin
              tags = ::YARD::Tags::Library.labels.keys.map(&:to_s).sort_by(&:length).reverse.join('|')
              /\A\s*#\s*@(#{tags})\b/
            end.freeze
            # @return [Regexp] matches YARD directive lines (@!macro, @!method, etc.)
            YARD_DIRECTIVE_PATTERN = /\A\s*#\s*@!/.freeze
            # Matches method/class/module/attribute/alias definitions (with optional visibility prefix)
            # and constant assignments (uppercase-leading identifier followed by =), both of which
            # YARD tracks and attaches preceding doc comments to.
            # Also matches define_method which YARD handles via a built-in dynamic handler.
            DEFINITION_PATTERN = /
              \A\s*(private\s+|protected\s+|public\s+)?
              (def |class |module |attr_reader|attr_writer|attr_accessor|attr_internal|alias_method\b|alias\b|define_method\b)
              |
              \A\s*[A-Z][A-Za-z0-9_:]*\s*=
            /x.freeze

            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.file && File.exist?(object.file)

              @scanned_files ||= {}
              return if @scanned_files[object.file]

              @scanned_files[object.file] = true
              scan_file(object.file, collector)
            end

            private

            # @param file [String] absolute path to the source file to scan
            # @param collector [Executor::ResultCollector] collector for output lines
            # @return [void]
            def scan_file(file, collector)
              lines = File.readlines(file, chomp: true)
              i = 0

              while i < lines.length
                if comment_line?(lines[i])
                  block_start = i
                  tags = []

                  has_directive = false
                  while i < lines.length && comment_line?(lines[i])
                    has_directive = true if directive_line?(lines[i])
                    tag = extract_yard_tag(lines[i])
                    tags << tag if tag
                    i += 1
                  end

                  # Skip blocks that contain @! directives - they are macro/method definitions,
                  # not orphaned doc comments.
                  next if has_directive || tags.empty?

                  # Skip trailing blank lines after the comment block
                  i += 1 while i < lines.length && lines[i].strip.empty?

                  if i >= lines.length || !definition_line?(lines[i])
                    collector.puts "#{file}:#{block_start + 1}: #{tags.uniq.join(',')}"
                  end
                else
                  i += 1
                end
              end
            end

            # @param line [String] a raw source line
            # @return [Boolean] true if the line is a Ruby comment (excluding magic comments)
            def comment_line?(line)
              stripped = line.strip
              stripped.start_with?('#') && !magic_comment?(stripped)
            end

            # @param stripped_line [String] a comment line with leading/trailing whitespace removed
            # @return [Boolean] true if the line is a Ruby magic comment (frozen_string_literal, encoding, etc.)
            def magic_comment?(stripped_line)
              stripped_line.match?(/\A#\s*(frozen[_-]string[_-]literal|encoding|warn[_-]indent|shareable[_-]constant[_-]value)\s*:/i)
            end

            # @param line [String] a raw source line
            # @return [Boolean] true if the line contains a YARD directive (@!macro, @!method, etc.)
            def directive_line?(line)
              line.match?(YARD_DIRECTIVE_PATTERN)
            end

            # @param line [String] a raw source line
            # @return [String, nil] the tag string (e.g. "@param") or nil if no known YARD tag found
            def extract_yard_tag(line)
              match = line.match(YARD_TAG_PATTERN)
              "@#{match[1]}" if match
            end

            # @param line [String] a raw source line
            # @return [Boolean] true if the line starts a YARD-documentable definition
            def definition_line?(line)
              line.match?(DEFINITION_PATTERN)
            end
          end
        end
      end
    end
  end
end
