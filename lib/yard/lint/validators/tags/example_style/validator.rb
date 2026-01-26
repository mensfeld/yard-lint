# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleStyle
          # Validator to check code style in @example tags using RuboCop/StandardRB
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks code style in @example tags using RuboCop or StandardRB.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.has_tag?(:example)

              # Get or initialize runner (memoized for performance)
              runner = get_or_create_runner
              return unless runner

              # Process each example
              example_tags = object.tags(:example)

              example_tags.each_with_index do |example, index|
                code = example.text
                next if code.nil? || code.empty?

                example_name = example.name || "Example #{index + 1}"

                # Run linter (pass file path for context/config discovery)
                offenses = runner.run(code, example_name, file_path: object.file)

                # Output each offense
                offenses.each do |offense|
                  collector.puts "#{object.file}:#{object.line}: #{object.title}"
                  collector.puts 'style_offense'
                  collector.puts example_name
                  collector.puts offense[:cop_name]
                  collector.puts offense[:message]
                end
              end
            end

            private

            # Get or create memoized runner instance
            # @return [RubocopRunner, nil] runner instance or nil if no linter available
            def get_or_create_runner
              return @runner if defined?(@runner)

              # Detect linter
              linter_type = config_or_default('Linter')
              detected_linter = LinterDetector.detect(linter_type)

              # Gracefully skip if no linter available
              if detected_linter == :none
                warn_once_about_missing_linter if ENV['DEBUG']
                @runner = nil
                return nil
              end

              # Initialize and memoize runner
              disabled_cops = config_or_default('DisabledCops')
              skip_patterns = config_or_default('SkipPatterns')
              @runner = RubocopRunner.new(
                linter: detected_linter,
                disabled_cops: disabled_cops,
                skip_patterns: skip_patterns
              )
            end

            # Warn once about missing linter (class-level tracking)
            def warn_once_about_missing_linter
              return if self.class.instance_variable_get(:@warned_about_linter)

              warn '[YARD::Lint] ExampleStyle validator enabled but no linter (RuboCop/StandardRB) found. Skipping.'
              self.class.instance_variable_set(:@warned_about_linter, true)
            end
          end
        end
      end
    end
  end
end
