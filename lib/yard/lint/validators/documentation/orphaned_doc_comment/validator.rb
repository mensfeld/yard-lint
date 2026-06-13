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
            # `attr\b` is matched after the `attr_*` variants so the bare `attr :name` form
            # (handled by YARD's attribute handler) is recognised without swallowing them.
            DEFINITION_PATTERN = /
              \A\s*(private\s+|protected\s+|public\s+)?
              (def |class |module |attr_reader|attr_writer|attr_accessor|attr_internal|attr\b|alias_method\b|alias\b|define_method\b)
              |
              \A\s*[A-Z][A-Za-z0-9_:]*\s*=
              |
              \A\s*\w+\s+def\b
            /x.freeze

            # Matches a DSL-style method call whose first argument is a symbol or string literal
            # (e.g. `ransacker :foo do`, `validates(:name, ...)`, `scope :active, -> { ... }`).
            # YARD's DSL handler turns such a call into a documentable method object when the
            # preceding comment carries an implicit-docstring tag, so a doc comment in front of
            # one of these is NOT orphaned.
            DSL_CALL_PATTERN = %r{\A\s*(?:[A-Za-z_][\w:]*\.)?(?<method>[a-z_]\w*[!?]?)(?:\s+|\s*\(\s*)(?::\w|:["']|["'])}.freeze
            # Matches a plain method call (optionally with a receiver), used when
            # the comment carries a @method/@attribute tag that names the object
            # YARD creates - then the call's argument shape does not matter.
            METHOD_CALL_PATTERN = /\A\s*(?:[A-Za-z_][\w:]*\.)?[a-z_]\w*[!?]?(?:[\s(]|\z)/.freeze
            # Matches a @method/@attribute tag that names a created object.
            NAMED_OBJECT_TAG_PATTERN = /\A\s*#\s*@(?:method|attribute)\s+\S/.freeze
            # Mirror of YARD::Handlers::Ruby::DSLHandlerMethods::IGNORE_METHODS - calls to these
            # are skipped by YARD's DSL handler, so a preceding doc comment really is dropped.
            # (The `attr*`/`alias*` entries are already covered by DEFINITION_PATTERN.)
            DSL_IGNORE_METHODS = %w[
              alias alias_method autoload attr attr_accessor attr_reader attr_writer
              extend include module_function public private protected private_constant
              private_class_method public_class_method
            ].freeze
            # YARD's DSL handler only creates a method object when the comment carries one of these
            # tags (see DSLHandlerMethods#implicit_docstring?). Matched on raw comment lines because
            # some (`@method`, `@attribute`, `@scope`, `@visibility`) are not in YARD's tag registry
            # and would otherwise be missed by YARD_TAG_PATTERN. Directive (`@!`) forms are excluded
            # here because directive blocks are already skipped upstream.
            IMPLICIT_DOCSTRING_TAG_PATTERN =
              /\A\s*#\s*@(?:method|attribute|overload|visibility|scope|return)\b/.freeze

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
                  has_implicit_tag = false
                  has_named_object_tag = false
                  while i < lines.length && comment_line?(lines[i])
                    has_directive = true if directive_line?(lines[i])
                    has_implicit_tag = true if implicit_docstring_tag?(lines[i])
                    has_named_object_tag = true if lines[i].match?(NAMED_OBJECT_TAG_PATTERN)
                    tag = extract_yard_tag(lines[i])
                    tags << tag if tag
                    i += 1
                  end

                  # Skip blocks that contain @! directives - they are macro/method definitions,
                  # not orphaned doc comments.
                  next if has_directive || tags.empty?

                  # Skip trailing blank lines after the comment block
                  i += 1 while i < lines.length && lines[i].strip.empty?

                  unless documentable?(lines[i], has_implicit_tag, has_named_object_tag)
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
              # A real magic comment has a single-token value (e.g. `true`,
              # `utf-8`), optionally followed by `;` (combined directives) or an
              # emacs `-*-` wrapper. Requiring that avoids treating prose that
              # merely starts with a magic-comment word - like
              # `# encoding: UTF-8 is assumed for all inputs` - as a magic
              # comment, which would split a documentation block.
              stripped_line.match?(
                /\A#\s*(?:-\*-\s*)?(frozen[_-]string[_-]literal|encoding|warn[_-]indent|shareable[_-]constant[_-]value)\s*:\s*\S+\s*(?:;|-\*-|\z)/i
              )
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

            # @param line [String, nil] the source line following the comment block, or nil at EOF
            # @param has_implicit_tag [Boolean] whether the comment block carries a tag that makes
            #   YARD's DSL handler emit a method object (see IMPLICIT_DOCSTRING_TAG_PATTERN)
            # @param has_named_object_tag [Boolean] whether the comment block carries a
            #   @method/@attribute tag naming the object YARD creates, so any following
            #   method call attaches the docstring regardless of its arguments
            # @return [Boolean] true if YARD will attach the comment to a documentable construct
            def documentable?(line, has_implicit_tag, has_named_object_tag = false)
              return false if line.nil?

              definition_line?(line) ||
                (has_implicit_tag && dsl_method_line?(line)) ||
                # A @method/@attribute tag names the object YARD creates, so any
                # following method call (regardless of its arguments) attaches it.
                (has_named_object_tag && line.match?(METHOD_CALL_PATTERN))
            end

            # @param line [String] a raw source line
            # @return [Boolean] true if the line starts a YARD-documentable definition
            def definition_line?(line)
              line.match?(DEFINITION_PATTERN)
            end

            # @param line [String] a raw source line
            # @return [Boolean] true if the line is a DSL-style call YARD's handler documents
            #   (symbol/string first argument and not one of YARD's ignored methods)
            def dsl_method_line?(line)
              match = line.match(DSL_CALL_PATTERN)
              return false unless match

              !DSL_IGNORE_METHODS.include?(match[:method])
            end

            # @param line [String] a raw source line
            # @return [Boolean] true if the comment line carries an implicit-docstring tag
            def implicit_docstring_tag?(line)
              line.match?(IMPLICIT_DOCSTRING_TAG_PATTERN)
            end
          end
        end
      end
    end
  end
end
