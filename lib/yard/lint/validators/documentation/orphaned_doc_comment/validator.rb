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

            YARD_TAG_PATTERN = /\A\s*#\s*@([a-z][a-z_]*)/.freeze
            YARD_DIRECTIVE_PATTERN = /\A\s*#\s*@!/.freeze
            # Matches method/class/module/attribute/alias definitions (with optional visibility prefix)
            # and constant assignments (uppercase-leading identifier followed by =), both of which
            # YARD tracks and attaches preceding doc comments to.
            DEFINITION_PATTERN = /
              \A\s*(private\s+|protected\s+|public\s+)?
              (def |class |module |attr_reader|attr_writer|attr_accessor|attr_internal|alias_method\b|alias\b)
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

                  # Skip blocks that contain @! directives — they are macro/method definitions,
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

            def comment_line?(line)
              stripped = line.strip
              stripped.start_with?('#') && !magic_comment?(stripped)
            end

            def magic_comment?(stripped_line)
              stripped_line.match?(/\A#\s*(frozen[_-]string[_-]literal|encoding|warn[_-]indent|shareable[_-]constant[_-]value)\s*:/i)
            end

            def directive_line?(line)
              line.match?(YARD_DIRECTIVE_PATTERN)
            end

            def extract_yard_tag(line)
              match = line.match(YARD_TAG_PATTERN)
              "@#{match[1]}" if match
            end

            def definition_line?(line)
              line.match?(DEFINITION_PATTERN)
            end
          end
        end
      end
    end
  end
end
