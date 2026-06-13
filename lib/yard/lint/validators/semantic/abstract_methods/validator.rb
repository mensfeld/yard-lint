# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Semantic
        module AbstractMethods
          # Validator to check @abstract methods have proper implementation
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks if @abstract methods have implementation.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.has_tag?(:abstract)
              return unless object.is_a?(YARD::CodeObjects::MethodObject)

              # Check if method has actual implementation (not just NotImplementedError)
              source = begin
                object.source
              rescue StandardError
                nil
              end
              return unless source && !source.empty?

              # Simple heuristic: abstract methods should be empty or raise NotImplementedError
              lines = source.split("\n").map(&:strip).reject(&:empty?)
              # Skip def line and end
              body_lines = lines[1...-1] || []

              # Merge statement continuations (a line ending in a comma or
              # backslash continues on the next line) so a multi-line
              # `raise NotImplementedError, "message"` is judged as one
              # statement rather than leaving a dangling argument line that
              # looks like a real implementation.
              body_lines = merge_continuations(body_lines)

              has_real_implementation = body_lines.any? do |line|
                !line.start_with?('#') &&
                  !line.include?('NotImplementedError') &&
                  !line.include?('raise') &&
                  line != 'end'
              end

              return unless has_real_implementation

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts 'has_implementation'
            end

            private

            # Joins lines that are continuations of the previous statement (the
            # previous line ends with a comma or a backslash) into a single
            # logical line.
            # @param lines [Array<String>] stripped body lines
            # @return [Array<String>] body lines with continuations merged
            def merge_continuations(lines)
              lines.each_with_object([]) do |line, merged|
                if !merged.empty? && merged.last.match?(/[,\\]\z/)
                  merged[-1] = "#{merged.last.chomp('\\').rstrip} #{line}"
                else
                  merged << line
                end
              end
            end
          end
        end
      end
    end
  end
end
