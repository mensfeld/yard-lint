# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedBooleanMethods
          # Runs a query that will pick all the boolean methods (ending with ?) that
          # do not have a return documented
          class Validator < Base
            # A top-level tag line; indented lines belong to the tag above them
            TAG_REGEX = /\A@(!?[\w.]+)/
            # A macro use or definition, capturing the macro name
            MACRO_REGEX = /\A@!?macro(?:\s+\[[^\]]*\])?\s+(\S+)/
            # Macros may reference other macros; stop at this depth
            MAX_MACRO_DEPTH = 5

            private_constant :TAG_REGEX, :MACRO_REGEX, :MAX_MACRO_DEPTH

            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Finds boolean methods (ending with ?) without a user-written @return tag.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              # Only check methods
              return unless object.type == :method
              # Skip aliases and implicit methods
              return if object.is_alias?
              return unless object.is_explicit?
              return if parent_class_allowed?(object)
              # Only check boolean methods (ending with ?)
              return unless object.name.to_s.end_with?('?')

              # Undocumented methods are reported by UndocumentedObjects
              return if object.docstring.all.empty?
              # YARD adds `@return [Boolean]` to every `?` method without one, so the
              # tags cannot tell; read the raw docstring instead
              return if user_return?(object.docstring.all)

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
            end

            private

            # Tells if the raw docstring text has a `@return` written by the user: at the
            # top level, inside an `@overload`, or carried by a macro. Text inside other
            # tags (e.g. an `@example` body) never counts.
            # @param text [String] raw docstring text
            # @param depth [Integer] macro nesting depth
            # @return [Boolean] true when a user-written `@return` is present
            def user_return?(text, depth = 0)
              tag_blocks(text).any? do |line, body|
                case line[TAG_REGEX, 1]
                when 'return'
                  true
                when 'overload'
                  user_return?(dedent(body), depth)
                when 'macro', '!macro'
                  macro_return?(line, depth)
                else
                  false
                end
              end
            end

            # Tells if the macro named in the line carries a `@return`
            # @param line [String] the `@macro` or `@!macro` line
            # @param depth [Integer] macro nesting depth
            # @return [Boolean] true when the macro text has a `@return` or the macro
            #   is not in the registry
            def macro_return?(line, depth)
              return false if depth >= MAX_MACRO_DEPTH

              name = line[MACRO_REGEX, 1]
              macro = name && YARD::CodeObjects::MacroObject.find(name)
              # Only the selected files are parsed, so a macro from another file is
              # unknown here; count it as written to report the same in every run
              return true unless macro

              user_return?(macro.macro_data.to_s, depth + 1)
            end

            # Splits the text into top-level tag lines and the indented lines below them
            # @param text [String] raw docstring text
            # @return [Array<Array(String, Array<String>)>] tag line and body lines
            def tag_blocks(text)
              text.lines.map(&:chomp).each_with_object([]) do |line, blocks|
                if line.match?(TAG_REGEX)
                  blocks << [line, []]
                elsif blocks.any? && (line.start_with?(/\s/) || line.empty?)
                  blocks.last.last << line
                end
              end
            end

            # Removes the common leading whitespace from the lines
            # @param lines [Array<String>] lines to dedent
            # @return [String] dedented text
            def dedent(lines)
              indent = lines.reject { |l| l.strip.empty? }.map { |l| l[/\A\s*/].size }.min || 0
              lines.map { |l| l[indent..] || '' }.join("\n")
            end
          end
        end
      end
    end
  end
end
