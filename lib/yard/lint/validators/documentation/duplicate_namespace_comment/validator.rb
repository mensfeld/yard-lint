# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module DuplicateNamespaceComment
          # Flags namespaces (modules and classes) that carry a documentation comment in
          # more than one file. YARD keeps only one docstring per object, so documenting
          # the same reopened namespace in several files silently discards all but one of
          # those comments. Because YARD does not record which reopening carried a comment,
          # the source is re-read at each definition site to detect the documented ones.
          class Validator < Base
            # Enable in-process execution including private/protected objects
            in_process visibility: :all

            # Comment lines that are directives or magic comments rather than
            # documentation. A definition preceded only by these is not "documented".
            IGNORED_COMMENT = /
              \A\#!                             # shebang
              |\A\#\s*frozen_string_literal:    # frozen_string_literal magic comment
              |\A\#\s*-\*-                       # editor modeline, e.g. -*- coding: utf-8 -*-
              |\A\#\s*(en)?coding[:=]            # encoding magic comment
              |\A\#\s*warn_indent:              # warn_indent magic comment
              |\A\#\s*rubocop:                  # rubocop directive
              |\A\#\s*:nodoc:                   # nodoc directive
              |\A\#\s*yard-lint:                # yard-lint inline directive
            /x

            private_constant :IGNORED_COMMENT

            # Execute query for a single object during in-process execution.
            # Emits one line per namespace documented in two or more files.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              # Only namespaces (modules and classes) get reopened across files.
              # NamespaceObject excludes methods, constants, and the like.
              return unless object.is_a?(YARD::CodeObjects::NamespaceObject)
              # A namespace defined in a single file can only be documented once.
              return if object.files.size < 2

              documented = object.files.select do |file, line|
                line && documented_site?(file, line)
              end

              return if documented.size < 2

              primary_file, primary_line = documented.first
              sites = documented.map { |file, line| "#{file}:#{line}" }.join('|')
              texts = documented.map { |file, line| doc_text(file, line) }
              conflict = texts.uniq.size > 1 ? 'differ' : 'same'

              collector.puts "#{primary_file}:#{primary_line}: #{object.title}\t#{sites}\t#{conflict}"
            end

            private

            # Whether the definition at a location is preceded by a real doc comment,
            # as opposed to no comment, a blank-separated (detached) comment, or only
            # directive/magic comments.
            # @param file [String] path to the source file
            # @param line [Integer] 1-based line of the namespace definition
            # @return [Boolean] true when the site carries documentation
            def documented_site?(file, line)
              !comment_lines(file, line).empty?
            end

            # Joins the documentation text at a location so identical and differing
            # documentation across sites can be told apart.
            # @param file [String] path to the source file
            # @param line [Integer] 1-based line of the namespace definition
            # @return [String] normalized comment text ('' when undocumented)
            def doc_text(file, line)
              comment_lines(file, line).join("\n")
            end

            # Collects the contiguous block of documentation comment lines directly
            # above a definition, dropping directive/magic comments. A blank line
            # between the comment and the definition detaches it (YARD behaviour), so
            # scanning stops at the first blank or non-comment line.
            # @param file [String] path to the source file
            # @param line [Integer] 1-based line of the namespace definition
            # @return [Array<String>] normalized documentation lines
            def comment_lines(file, line)
              lines = source_lines(file)
              return [] if lines.empty?

              collected = []
              index = line - 2 # zero-based line directly above the definition

              while index >= 0
                text = lines[index].strip
                break if text.empty? || !text.start_with?('#')

                collected << text unless text.match?(IGNORED_COMMENT)
                index -= 1
              end

              collected
            end

            # Reads source lines for a file, tolerating unreadable paths so a single
            # bad location drops only its own site instead of hiding the whole object.
            # @param file [String] path to the source file
            # @return [Array<String>] file lines, or an empty array when unreadable
            def source_lines(file)
              cached_lines(file)
            rescue SystemCallError, IOError
              []
            end
          end
        end
      end
    end
  end
end
