# frozen_string_literal: true

module Yard
  module Lint
    # Main runner class that orchestrates the YARD validation process
    class Runner
      attr_reader :config, :selection

      # @param selection [Array<String>] array with ruby files to check
      # @param config [Yard::Lint::Config] configuration object
      def initialize(selection, config = Config.new)
        @selection = Array(selection).flatten
        @config = config
      end

      # Runs all validators and returns a Result object
      # @return [Yard::Lint::Result] result object with all offenses
      def run
        raw_results = run_validators
        parsed_results = parse_results(raw_results)
        build_result(parsed_results)
      end

      private

      # Run all validators
      # Automatically runs all validators from ConfigLoader::ALL_VALIDATORS if enabled
      # @return [Hash] hash with raw results from all validators
      def run_validators
        results = {}

        # Iterate through all registered validators
        ConfigLoader::ALL_VALIDATORS.each do |validator_name|
          # Check if validator is enabled in config
          next unless config.validator_enabled?(validator_name)

          # Get the validator module dynamically
          validator_module = ConfigLoader.validator_module(validator_name)

          # Run the validator if it has a module (validators with modules have Validator classes)
          # Validators without modules (like Documentation/UndocumentedObjects) are handled by Stats
          run_and_store_validator(validator_module, results) if validator_module
        end

        results
      end

      # Run a validator and store its result using the module's ID
      # @param validator_module [Module] validator module (e.g., Validators::Stats)
      # @param results [Hash] hash to store results in
      def run_and_store_validator(validator_module, results)
        results[validator_module.id] = run_validator(validator_module::Validator)
      end

      # Run a single validator
      # @param validator_class [Class] validator class to instantiate and run
      # @return [Hash] hash with stdout, stderr and exit_code keys
      def run_validator(validator_class)
        validator_class.new(config, selection).call
      end

      # Parse raw results from validators
      # @param raw [Hash] hash with raw results from all validators
      # @return [Hash] hash with parsed results
      def parse_results(raw)
        results = {
          warnings: build_warnings(raw),
          undocumented: build_undocumented(raw)
        }

        # Add results for enabled validators
        if config.validator_enabled?('Documentation/UndocumentedMethodArguments')
          results[:undocumented_method_arguments] = build_undocumented_method_arguments(raw)
        end

        results[:invalid_tags_types] = build_invalid_tags_types(raw) if config.validator_enabled?('Tags/InvalidTypes')

        results[:invalid_tags_order] = build_invalid_tags_order(raw) if config.validator_enabled?('Tags/Order')

        results[:api_tags] = build_api_tags(raw) if config.validator_enabled?('Tags/ApiTags')

        if config.validator_enabled?('Semantic/AbstractMethods')
          results[:abstract_methods] = build_abstract_methods(raw)
        end

        results[:option_tags] = build_option_tags(raw) if config.validator_enabled?('Tags/OptionTags')

        results
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] results from the warning parsers
      def build_warnings(raw)
        stats = raw.dig(Validators::Warnings::Stats.id, :stdout)

        # List all warning parsers explicitly
        warning_parsers = [
          Validators::Warnings::Stats::UnknownTag,
          Validators::Warnings::Stats::UnknownDirective,
          Validators::Warnings::Stats::UnknownParameterName,
          Validators::Warnings::Stats::InvalidTagFormat,
          Validators::Warnings::Stats::InvalidDirectiveFormat,
          Validators::Warnings::Stats::DuplicatedParameterName
        ]

        warning_parsers
          .map { |klass| klass.new.call(stats) }
          .flatten
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] Array with undocumented objects details
      def build_undocumented(raw)
        all = Validators::Documentation::UndocumentedObjects::Parser.new.call(raw.dig(
                                                                                Validators::Documentation::UndocumentedObjects.id, :stdout
                                                                              ))

        boolean = Validators::Documentation::UndocumentedBooleanMethods::Parser.new.call(raw.dig(
                                                                                           Validators::Documentation::UndocumentedBooleanMethods.id, :stdout
                                                                                         ))

        all + boolean
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with all warnings informations from yard list on missing docs
      def build_undocumented_method_arguments(raw)
        Validators::Documentation::UndocumentedMethodArguments::Parser.new.call(raw.dig(
                                                                                  Validators::Documentation::UndocumentedMethodArguments.id, :stdout
                                                                                ))
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with location info of elements with invalid tag types
      def build_invalid_tags_types(raw)
        Validators::Tags::InvalidTypes::Parser.new.call(raw.dig(Validators::Tags::InvalidTypes.id, :stdout))
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with location info of elements with invalid tags order
      def build_invalid_tags_order(raw)
        Validators::Tags::Order::Parser.new.call(raw.dig(Validators::Tags::Order.id, :stdout))
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with API tag violations
      def build_api_tags(raw)
        return [] unless raw[Validators::Tags::ApiTags.id]

        Validators::Tags::ApiTags::Parser.new.call(raw.dig(Validators::Tags::ApiTags.id, :stdout))
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with abstract method violations
      def build_abstract_methods(raw)
        return [] unless raw[Validators::Semantic::AbstractMethods.id]

        Validators::Semantic::AbstractMethods::Parser.new.call(raw.dig(Validators::Semantic::AbstractMethods.id,
                                                                       :stdout))
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with option tag violations
      def build_option_tags(raw)
        return [] unless raw[Validators::Tags::OptionTags.id]

        Validators::Tags::OptionTags::Parser.new.call(raw.dig(Validators::Tags::OptionTags.id, :stdout))
      end

      # Build final result object
      # @param parsed [Hash] parsed results
      # @return [Yard::Lint::Result] result object
      def build_result(parsed)
        Result.new(parsed, config)
      end
    end
  end
end
