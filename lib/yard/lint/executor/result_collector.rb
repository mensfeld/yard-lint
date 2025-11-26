# frozen_string_literal: true

module Yard
  module Lint
    module Executor
      # Collects query output in a format matching shell stdout.
      # Used by validators to write their results during in-process execution.
      class ResultCollector
        def initialize
          @lines = []
          @mutex = Mutex.new
        end

        # Add a single line to the output
        # @param line [String, Object] content to add (will be converted to string)
        # @return [void]
        def puts(line)
          @mutex.synchronize { @lines << line.to_s }
        end

        # Add multiple lines by splitting content on newlines.
        # Each line is added separately to the output buffer.
        # @param content [String] multiline string to split and add
        # @return [void]
        def print(content)
          content.to_s.each_line { |line| puts(line.chomp) }
        end

        # Get the collected output as a single string
        # @return [String] all lines joined with newlines
        def to_stdout
          @lines.join("\n")
        end

        # Check if any output has been collected
        # @return [Boolean]
        def empty?
          @lines.empty?
        end

        # Get the number of lines collected
        # @return [Integer]
        def size
          @lines.size
        end

        # Clear all collected output
        # @return [void]
        def clear!
          @mutex.synchronize { @lines.clear }
        end
      end
    end
  end
end
