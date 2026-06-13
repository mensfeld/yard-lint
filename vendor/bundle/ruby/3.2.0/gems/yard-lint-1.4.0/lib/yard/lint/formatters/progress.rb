# frozen_string_literal: true

module Yard
  module Lint
    # Output formatters for displaying linting progress and results
    module Formatters
      # Simple progress formatter that shows which validator is running
      # Similar to RuboCop's progress display
      class Progress
        # Initialize progress formatter
        # @param output [IO] output stream (default: $stdout)
        def initialize(output = $stdout)
          @output = output
          @total = 0
          @current = 0
        end

        # Start progress display
        # @param total [Integer] total number of validators
        def start(total)
          @total = total
          @current = 0
          @output.print "Inspecting with #{total} validators\n"
        end

        # Update progress with current validator
        # @param current [Integer] current validator number
        # @param validator_name [String] name of the validator
        def update(current, validator_name)
          @current = current
          # Clear line and show progress
          @output.print "\r\e[K" # Clear line
          @output.print format(
            '[%<current>d/%<total>d] %<name>s',
            current: current,
            total: @total,
            name: validator_name
          )
          @output.flush
        end

        # Finish progress display
        def finish
          @output.print "\r\e[K" # Clear the progress line
          @output.flush
        end
      end
    end
  end
end
