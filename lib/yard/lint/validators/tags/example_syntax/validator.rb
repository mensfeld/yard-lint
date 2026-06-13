# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleSyntax
          # Validator to check syntax of code in @example tags
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks syntax of code in @example tags.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.has_tag?(:example)

              example_tags = object.tags(:example)

              example_tags.each_with_index do |example, index|
                code = example.text
                next if code.nil? || code.empty?

                # Clean the code: strip YARD output indicators (# =>) and
                # everything after them, but only when the "# =>" is a real
                # trailing comment - not when it appears inside a string literal
                code_lines = code.split("\n").map do |line|
                  strip_output_marker(line)
                end

                cleaned_code = code_lines.join("\n").strip
                next if cleaned_code.empty?

                # Check if code looks incomplete (single expression without context)
                lines = cleaned_code.split("\n").reject { |l| l.strip.empty? || l.strip.start_with?('#') }

                # Skip if it is a single line that looks like an incomplete expression
                if lines.size == 1
                  line = lines.first.strip
                  # Skip method calls, variable references, or simple expressions
                  next if line.match?(/^[a-z_][a-z0-9_]*(\.| |$)/) ||
                          (line.match?(/^[A-Z]/) && !line.match?(/^(class|module|def)\s/))
                end

                # Try to parse the code
                # Suppress Ruby parser warnings (like "... at EOL, should be parenthesized?")
                # that can occur during compilation of valid but stylistically questionable code
                original_verbose = $VERBOSE
                begin
                  $VERBOSE = nil
                  RubyVM::InstructionSequence.compile(cleaned_code)
                rescue SyntaxError => e
                  example_name = example.name.to_s.empty? ? "Example #{index + 1}" : example.name
                  collector.puts "#{object.file}:#{object.line}: #{object.title}"
                  collector.puts 'syntax_error'
                  collector.puts example_name
                  collector.puts e.message
                rescue ScriptError, EncodingError => e
                  # Non-syntax script errors (LoadError, NotImplementedError) and encoding
                  # issues should be logged but not reported as syntax errors.
                  # We only validate syntax, not runtime semantics or encoding validity.
                  warn "[YARD::Lint] Example code error in #{object.path}: #{e.class}: #{e.message}" if ENV['DEBUG']
                  next
                ensure
                  $VERBOSE = original_verbose
                end
              end
            end

            private

            # Removes a trailing YARD `# => result` output marker from a line of
            # example code, but only when the `#` actually starts a comment - a
            # `#` inside a string or character literal is left untouched, so a
            # string such as `"result # => x"` is not corrupted into an
            # unterminated literal.
            # @param line [String] a single line of example source
            # @return [String] the line with a trailing output marker removed
            def strip_output_marker(line)
              in_single = false
              in_double = false
              i = 0

              while i < line.length
                char = line[i]

                if (in_single || in_double) && char == '\\'
                  i += 2
                  next
                end

                if in_single
                  in_single = false if char == "'"
                elsif in_double
                  in_double = false if char == '"'
                elsif char == "'"
                  in_single = true
                elsif char == '"'
                  in_double = true
                elsif char == '#'
                  # A comment starts here (outside any string). Strip it only
                  # when it is a YARD output marker; leave ordinary comments,
                  # which the Ruby parser handles fine.
                  return line[0...i].rstrip if line[i..].match?(/\A#\s*=>/)

                  break
                end

                i += 1
              end

              line
            end
          end
        end
      end
    end
  end
end
