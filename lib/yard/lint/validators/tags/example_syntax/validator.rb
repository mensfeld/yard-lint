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

                # Clean the code: strip output indicators (#=>) and everything after it
                code_lines = code.split("\n").map do |line|
                  line.sub(/\s*#\s*=>.*$/, '')
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
                begin
                  RubyVM::InstructionSequence.compile(cleaned_code)
                rescue SyntaxError => e
                  example_name = example.name || "Example #{index + 1}"
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
                end
              end
            end
          end
        end
      end
    end
  end
end
