# frozen_string_literal: true

module Yard
  module Lint
    # Main runner class that orchestrates the YARD validation process
    class Runner
      attr_reader :config, :selection
      attr_accessor :progress_formatter

      # @param selection [Array<String>] array with ruby files to check
      # @param config [Yard::Lint::Config] configuration object
      def initialize(selection, config = Config.new)
        @selection = Array(selection).flatten
        @config = config
        @result_builder = ResultBuilder.new(config)
        @progress_formatter = nil
      end

      # Runs all validators and returns a Result object
      # @return [Yard::Lint::Result] result object with all offenses
      def run
        raw_results = run_validators
        parsed_results = parse_results(raw_results)
        build_result(parsed_results, @selection)
      end

      private

      # Run all validators
      # Automatically runs all validators from ConfigLoader::ALL_VALIDATORS if enabled
      # @return [Hash] hash with raw results from all validators
      def run_validators
        results = {}
        enabled_validators = ConfigLoader::ALL_VALIDATORS.select do |name|
          config.validator_enabled?(name)
        end

        @progress_formatter&.start(enabled_validators.size)

        # Iterate through all registered validators
        enabled_validators.each_with_index do |validator_name, index|
          # Get the validator namespace and config
          validator_namespace = ConfigLoader.validator_module(validator_name)
          validator_cfg = ConfigLoader.validator_config(validator_name)

          # Show progress before running validator
          @progress_formatter&.update(index + 1, validator_name)

          # Run the validator if it has a module
          # (validators with modules have Validator classes)
          if validator_namespace
            run_and_store_validator(validator_namespace, validator_cfg, results, validator_name)
          end
        end

        @progress_formatter&.finish

        results
      end

      # Run a validator and store its result using the module's ID
      # @param validator_namespace [Module] validator namespace module (e.g., Validators::Tags::Order)
      # @param validator_config [Class] validator config class
      # @param results [Hash] hash to store results in
      # @param validator_name [String] full validator name for per-validator exclusions
      def run_and_store_validator(
        validator_namespace, validator_config, results, validator_name
      )
        results[validator_config.id] = run_validator(
          validator_namespace::Validator,
          validator_name
        )
      end

      # Run a single validator with per-validator file filtering
      # @param validator_class [Class] validator class to instantiate and run
      # @param validator_name [String] full validator name for exclusions
      # @return [Hash] hash with stdout, stderr and exit_code keys
      def run_validator(validator_class, validator_name)
        validator_selection = filter_files_for_validator(validator_name, selection)
        validator_class.new(config, validator_selection).call
      end

      # Filter files for a specific validator based on per-validator exclusions
      # @param validator_name [String] full validator name
      # @param files [Array<String>] array of file paths
      # @return [Array<String>] filtered array of file paths
      def filter_files_for_validator(validator_name, files)
        validator_excludes = config.validator_exclude(validator_name)
        return files if validator_excludes.empty?

        files.reject do |file|
          validator_excludes.any? do |pattern|
            File.fnmatch(pattern, file, File::FNM_PATHNAME | File::FNM_EXTGLOB)
          end
        end
      end

      # Filter result offenses based on per-validator exclusions
      # Removes offenses where the file path matches exclusion patterns
      # @param validator_name [String] full validator name
      # @param result [Results::Base] result object with offenses
      # @return [Results::Base, nil] result with filtered offenses, or nil if no offenses remain
      def filter_result_offenses(validator_name, result)
        validator_excludes = config.validator_all_excludes(validator_name)
        return result if validator_excludes.empty?

        working_dir = Dir.pwd

        filtered_offenses = result.offenses.reject do |offense|
          file_path = offense[:location] || offense[:file]
          next true unless file_path

          # Convert to relative path for pattern matching
          relative_path = if file_path.start_with?(working_dir)
                            file_path.sub(%r{^#{Regexp.escape(working_dir)}/}, '')
                          else
                            file_path
                          end

          # Check if file matches any exclusion pattern
          validator_excludes.any? do |pattern|
            File.fnmatch(pattern, relative_path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
          end
        end

        # Return nil if no offenses remain after filtering
        return nil if filtered_offenses.empty?

        # Instead of creating a new Result object (which would rebuild messages),
        # just modify the existing result object's offenses array
        # This preserves all the processed offense data including enhanced messages
        result.offenses = filtered_offenses
        result
      end

      # Parse raw results from validators and create Result objects
      # Delegates result building to ResultBuilder
      # @param raw [Hash] hash with raw results from all validators
      # @return [Array<Results::Base>] array of Result objects
      def parse_results(raw)
        results = []

        # Iterate through all registered validators and build results
        ConfigLoader::ALL_VALIDATORS.each do |validator_name|
          next unless config.validator_enabled?(validator_name)

          result = @result_builder.build(validator_name, raw)
          next unless result

          # Filter offenses based on per-validator exclusions
          filtered_result = filter_result_offenses(validator_name, result)
          results << filtered_result if filtered_result
        end

        results
      end

      # Build final result object
      # @param results [Array<Results::Base>] array of validator result objects
      # @param files [Array<String>] array of files that were analyzed
      # @return [Results::Aggregate] aggregate result object
      def build_result(results, files)
        Results::Aggregate.new(results, config, files)
      end
    end
  end
end
