# frozen_string_literal: true

require 'ripper'

module Yard
  module Lint
    module Validators
      module Tags
        module MissingYield
          # Detects methods that call `yield` but lack @yield/@yieldparam/@yieldreturn documentation
          class Validator < Base
            # Enable in-process execution with all visibility (private methods can yield too)
            in_process visibility: :all

            # Matches the `yield` keyword. The negative lookbehind `(?<![:.])`
            # prevents matching method calls like `Fiber.yield` or `yielder.yield`
            # and symbol literals like `:yield`. The negative lookahead `(?!:)`
            # prevents matching the label form - a symbol hash key or keyword
            # argument like `{ yield: true }` (a real block yield is never
            # directly followed by a colon: `yield ::Const` has a space).
            # Word boundaries ensure `yield_self` and similar identifiers are
            # not matched.
            # Known limitation: `yield` inside regex literals (e.g. /yield/) is
            # not stripped before scanning; it is rare enough to be acceptable.
            YIELD_PATTERN = /(?<![:.])\byield\b(?!:)/.freeze

            # @return [Regexp] matches full-line Ruby comments
            COMMENT_LINE_PATTERN = /\A\s*#/.freeze

            # Matches simple single- and double-quoted string literals to strip before
            # scanning for the yield keyword, reducing false positives from strings
            # that contain the word "yield".
            STRING_LITERAL_PATTERN = /("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/.freeze

            # Matches user-written @yield, @yieldparam, or @yieldreturn tags in raw
            # docstring text. YARD infers @yield automatically for bare `yield expr`
            # statements and adds it to object.tags(), so we check docstring.all (the
            # raw source text) rather than the parsed tag list to avoid counting
            # YARD-inferred tags as explicit documentation.
            YIELD_TAG_PATTERN = /^\s*@yield(?:param|return)?(?:\s|$)/.freeze

            # Execute query for a single object during in-process execution.
            # Flags methods that yield without a @yield, @yieldparam, or @yieldreturn tag.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.type == :method
              return if object.is_alias?
              return unless object.is_explicit?
              return unless object.source
              return if yield_documented?(object)
              return unless source_contains_yield?(object.source)

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
            end

            private

            # @param object [YARD::CodeObjects::MethodObject] the method to check
            # @return [Boolean] true if the user explicitly wrote a yield-related tag
            def yield_documented?(object)
              object.docstring.all.match?(YIELD_TAG_PATTERN)
            end

            # @param source [String] raw method source code
            # @return [Boolean] true if the method itself yields (ignoring yields
            #   that belong to a nested method definition)
            def source_contains_yield?(source)
              sexp = ::Ripper.sexp(source)
              # If the isolated source does not parse on its own, fall back to the
              # line scan rather than silently missing a yield.
              return yield_in_lines?(source) if sexp.nil?

              method_level_yield?(sexp)
            end

            # Walks the Ripper S-expression for a `yield` that belongs to the
            # method being analysed - one nested directly inside this definition
            # rather than inside a nested `def`. `def_depth` counts enclosing
            # method definitions; the analysed method's own body is depth 1, so a
            # yield inside a nested `def` (depth 2+) is correctly ignored.
            # @param node [Object] a Ripper S-expression node
            # @param def_depth [Integer] number of enclosing `def`/`defs` nodes
            # @return [Boolean] true if a yield at the method's own level is found
            def method_level_yield?(node, def_depth = 0)
              return false unless node.is_a?(::Array)

              case node.first
              when :yield, :yield0
                return def_depth == 1
              when :def, :defs
                return node.any? { |child| method_level_yield?(child, def_depth + 1) }
              end

              node.any? { |child| method_level_yield?(child, def_depth) }
            end

            # Line-based fallback used when Ripper cannot parse the source.
            # @param source [String] raw method source code
            # @return [Boolean] true if a `yield` keyword appears on a code line
            def yield_in_lines?(source)
              source.each_line.any? do |line|
                next false if line.match?(COMMENT_LINE_PATTERN)

                sanitized = line.gsub(STRING_LITERAL_PATTERN, '""')
                sanitized = sanitized.sub(/#.*$/, '')
                sanitized.match?(YIELD_PATTERN)
              end
            end
          end
        end
      end
    end
  end
end
