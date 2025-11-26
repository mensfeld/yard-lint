# frozen_string_literal: true

module Yard
  module Lint
    module Executor
      # Executes validator queries against the shared registry.
      # Handles visibility filtering and file exclusions per validator.
      class QueryExecutor
        # @param registry [InProcessRegistry] the shared registry instance
        def initialize(registry)
          @registry = registry
        end

        # Execute a validator's query against the registry
        # @param validator [Validators::Base] validator instance with in_process_query method
        # @param file_selection [Array<String>] files to include in the query
        # @return [Hash] result hash with :stdout, :stderr, :exit_code keys
        def execute(validator, file_selection: nil)
          validator_name = validator.class.validator_name

          # Determine visibility: if config has --private/--protected, use :all
          visibility = determine_visibility(validator)

          # Get file excludes from config
          excludes = if validator_name && validator.config
                       validator.config.validator_exclude(validator_name)
                     else
                       []
                     end

          objects = @registry.objects_for_validator(
            visibility: visibility,
            file_excludes: excludes,
            file_selection: file_selection
          )

          collector = ResultCollector.new

          objects.each do |object|
            # Skip objects without file/line info
            next unless object.file && object.line

            execute_query_for_object(validator, object, collector)
          end

          build_result(collector)
        end

        private

        # Execute query for a single object, handling errors gracefully
        # @param validator [Validators::Base] validator instance
        # @param object [YARD::CodeObjects::Base] code object to query
        # @param collector [ResultCollector] output collector
        # @return [void]
        def execute_query_for_object(validator, object, collector)
          validator.in_process_query(object, collector)
        rescue StandardError
          # Skip objects that cause errors (mirrors YARD CLI behavior)
          # Errors in individual objects shouldn't fail the entire validator
        end

        # Build the result hash matching shell command output format
        # @param collector [ResultCollector] output collector
        # @return [Hash] result hash with :stdout, :stderr, :exit_code keys
        def build_result(collector)
          {
            stdout: collector.to_stdout,
            stderr: '',
            exit_code: 0
          }
        end

        # Determine visibility setting based on validator and config
        # If config has --private or --protected in YardOptions, use :all
        # Otherwise use the validator's declared visibility
        # @param validator [Validators::Base] validator instance
        # @return [Symbol] visibility setting (:public or :all)
        def determine_visibility(validator)
          # Check if config specifies private/protected analysis
          if validator.config
            yard_options = validator.config.all_validators['YardOptions'] || []
            if yard_options.any? { |opt| opt.include?('--private') || opt.include?('--protected') }
              return :all
            end
          end

          # Fall back to validator's declared visibility
          validator.class.in_process_visibility || :public
        end
      end
    end
  end
end
