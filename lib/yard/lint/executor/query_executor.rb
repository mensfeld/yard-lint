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
        rescue NotImplementedError, NoMethodError
          # These indicate bugs in validator implementation - re-raise them
          raise
        rescue StandardError => e
          # Skip objects that cause data-related errors (mirrors YARD CLI behavior).
          # Some code objects may have malformed data that causes errors during validation.
          # We log these in debug mode but don't fail the entire validator run.
          return unless ENV['DEBUG']

          warn "[YARD::Lint] Validator #{validator.class} error on #{object.path}: #{e.class}: #{e.message}"
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
        # If config explicitly sets empty YardOptions, use :public (override validator default)
        # Otherwise use the validator's declared visibility
        # @param validator [Validators::Base] validator instance
        # @return [Symbol] visibility setting (:public or :all)
        def determine_visibility(validator)
          return validator.class.in_process_visibility || :public unless validator.config

          validator_name = validator.class.validator_name
          yard_options = validator.config.validator_yard_options(validator_name)

          # If YardOptions contains --private or --protected, use :all visibility
          if yard_options.any? { |opt| opt.include?('--private') || opt.include?('--protected') }
            return :all
          end

          # Check if validator has explicit YardOptions set in config
          # If explicitly set (even to empty), respect that choice and use :public
          validator_cfg = validator.config.validators[validator_name] || {}
          return :public if validator_cfg.key?('YardOptions')

          # No explicit YardOptions - fall back to validator's declared visibility
          validator.class.in_process_visibility || :public
        end
      end
    end
  end
end
