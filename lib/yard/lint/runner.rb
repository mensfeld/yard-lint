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
      # @return [Hash] hash with raw results from all validators
      def run_validators
        results = {
          stats: run_validator(Validators::Stats),
          undocumented_method_arguments: run_validator(Validators::UndocumentedMethodArguments),
          invalid_tags_types: run_validator(Validators::InvalidTagsTypes),
          invalid_tags_order: run_validator(Validators::InvalidTagsOrder),
          undocumented_boolean_methods: run_validator(Validators::UndocumentedBooleanMethods)
        }

        # Add optional validators based on config
        results[:api_tags] = run_validator(Validators::ApiTags) if config.require_api_tags
        if config.validate_abstract_methods
          results[:abstract_methods] = run_validator(Validators::AbstractMethods)
        end
        if config.validate_option_tags
          results[:option_tags] = run_validator(Validators::OptionTags)
        end

        results
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
          undocumented: build_undocumented(raw),
          undocumented_method_arguments: build_undocumented_method_arguments(raw),
          invalid_tags_types: build_invalid_tags_types(raw),
          invalid_tags_order: build_invalid_tags_order(raw)
        }

        # Add optional validator results based on config
        results[:api_tags] = build_api_tags(raw) if config.require_api_tags
        if config.validate_abstract_methods
          results[:abstract_methods] = build_abstract_methods(raw)
        end
        results[:option_tags] = build_option_tags(raw) if config.validate_option_tags

        results
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] results from the warning parsers
      def build_warnings(raw)
        stats = raw.dig(:stats, :stdout)

        # List all warning parsers explicitly
        warning_parsers = [
          Parsers::UnknownTag,
          Parsers::UnknownDirective,
          Parsers::UnknownParameterName,
          Parsers::InvalidTagFormat,
          Parsers::InvalidDirectiveFormat,
          Parsers::DuplicatedParameterName
        ]

        warning_parsers
          .map { |klass| klass.new.call(stats) }
          .flatten
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] Array with undocumented objects details
      def build_undocumented(raw)
        all = Parsers::UndocumentedObject.new.call(raw.dig(:stats, :stdout))

        boolean = Parsers::UndocumentedBooleanMethods.new.call(raw.dig(:undocumented_boolean_methods, :stdout))

        all + boolean
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with all warnings informations from yard list on missing docs
      def build_undocumented_method_arguments(raw)
        Parsers::UndocumentedMethodArguments.new.call(raw.dig(:undocumented_method_arguments, :stdout))
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with location info of elements with invalid tag types
      def build_invalid_tags_types(raw)
        Parsers::UndocumentedMethodArguments.new.call(raw.dig(:invalid_tags_types, :stdout))
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with location info of elements with invalid tags order
      def build_invalid_tags_order(raw)
        Parsers::InvalidTagsOrder.new.call(raw.dig(:invalid_tags_order, :stdout))
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with API tag violations
      def build_api_tags(raw)
        return [] unless raw[:api_tags]

        Parsers::ApiTags.new.call(raw.dig(:api_tags, :stdout))
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with abstract method violations
      def build_abstract_methods(raw)
        return [] unless raw[:abstract_methods]

        Parsers::AbstractMethods.new.call(raw.dig(:abstract_methods, :stdout))
      end

      # @param raw [Hash] raw stdout output result from yard commands
      # @return [Array<Hash>] array with option tag violations
      def build_option_tags(raw)
        return [] unless raw[:option_tags]

        Parsers::OptionTags.new.call(raw.dig(:option_tags, :stdout))
      end

      # Build final result object
      # @param parsed [Hash] parsed results
      # @return [Yard::Lint::Result] result object
      def build_result(parsed)
        Result.new(parsed)
      end
    end
  end
end
