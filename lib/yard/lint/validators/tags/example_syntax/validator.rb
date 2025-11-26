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
                rescue StandardError
                  # Other errors (like NameError, ArgumentError) are fine
                  # We only check syntax, not semantics
                  next
                end
              end
            end

            private

            # Runs yard list query to find objects with invalid syntax in @example tags
            # @param dir [String] dir where the yard db is (or where it should be generated)
            # @param file_list_path [String] path to temp file containing file paths (one per line)
            # @return [Hash] shell command execution hash results
            def yard_cmd(dir, file_list_path)
              cmd = <<~CMD
                cat #{Shellwords.escape(file_list_path)} | xargs yard list \
                --private \
                --protected \
                -b #{Shellwords.escape(dir)}
              CMD
              cmd = cmd.tr("\n", ' ')
              cmd = cmd.gsub('yard list', "yard list --query #{query}")

              shell(cmd)
            end

            # @return [String] yard query to find @example tags with syntax errors
            def query
              <<~QUERY
                '
                  if object.has_tag?(:example)
                    example_tags = object.tags(:example)

                    example_tags.each_with_index do |example, index|
                      code = example.text
                      next if code.nil? || code.empty?

                      # Clean the code: strip output indicators (#=>) and everything after it
                      code_lines = code.split("\\n").map do |line|
                        line.sub(/\\s*#\\s*=>.*$/, "")
                      end

                      cleaned_code = code_lines.join("\\n").strip
                      next if cleaned_code.empty?

                      # Check if code looks incomplete (single expression without context)
                      # Skip validation for these cases
                      lines = cleaned_code.split("\\n").reject { |l| l.strip.empty? || l.strip.start_with?("#") }

                      # Skip if it is a single line that looks like an incomplete expression
                      if lines.size == 1
                        line = lines.first.strip
                        # Skip method calls, variable references, or simple expressions
                        # These are likely incomplete snippets showing usage
                        if line.match?(/^[a-z_][a-z0-9_]*(\\.| |$)/) || line.match?(/^[A-Z]/) && !line.match?(/^(class|module|def)\\s/)
                          next
                        end
                      end

                      # Try to parse the code
                      begin
                        RubyVM::InstructionSequence.compile(cleaned_code)
                      rescue SyntaxError => e
                        # Report syntax errors
                        example_name = example.name || "Example " + (index + 1).to_s
                        puts object.file + ":" + object.line.to_s + ": " + object.title
                        puts "syntax_error"
                        puts example_name
                        puts e.message
                      rescue => e
                        # Other errors (like NameError, ArgumentError) are fine
                        # We only check syntax, not semantics
                        next
                      end
                    end
                  end
                  false
                '
              QUERY
            end
          end
        end
      end
    end
  end
end
