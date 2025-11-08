# frozen_string_literal: true

module Yard
  module Lint
    # Builds result objects from raw validator output
    # Handles standard validators, multi-parser validators, and composite validators
    class ResultBuilder
      attr_reader :config

      # @param config [Config] configuration object
      def initialize(config)
        @config = config
      end

      # Build result for a single validator
      # Uses convention-based discovery to handle all validator types uniformly
      # @param validator_name [String] validator name (e.g., 'Tags/Order')
      # @param raw [Hash] raw results from all validators
      # @return [Results::Base, nil] result object or nil if no offenses
      def build(validator_name, raw)
        validator_module = ConfigLoader.validator_module(validator_name)
        validator_cfg = ConfigLoader.validator_config(validator_name)
        return nil unless validator_module && validator_cfg

        # Skip if this validator is a child of a composite
        return nil if composite_child?(validator_name)

        # Handle composite validators (those that combine multiple validators)
        unless validator_cfg.combines_with.empty?
          return build_composite_result(validator_module, validator_cfg, raw)
        end

        # Handle standard validators (single or multi-parser)
        build_standard_result(validator_module, validator_cfg, raw)
      end

      private

      # Check if a validator is a child of a composite validator
      # @param validator_name [String] validator name to check
      # @return [Boolean] true if this is a composite child
      def composite_child?(validator_name)
        ConfigLoader::ALL_VALIDATORS.any? do |parent_name|
          parent_cfg = ConfigLoader.validator_config(parent_name)
          next unless parent_cfg

          parent_cfg.combines_with.include?(validator_name)
        end
      end

      # Build result for a composite validator (combines multiple validators)
      # @param validator_module [Module] validator namespace module
      # @param validator_cfg [Class] validator config class
      # @param raw [Hash] raw results
      # @return [Results::Base, nil] composite result or nil
      def build_composite_result(validator_module, validator_cfg, raw)
        # Collect all child validators (modules + configs)
        children = validator_cfg.combines_with.filter_map do |child_name|
          child_mod = ConfigLoader.validator_module(child_name)
          child_cfg = ConfigLoader.validator_config(child_name)
          [child_mod, child_cfg] if child_mod && child_cfg
        end

        # All validators (parent + children)
        all_validators = [[validator_module, validator_cfg]] + children

        # Parse output from all validators
        combined = all_validators.flat_map do |mod, cfg|
          parse_validator_output(mod, cfg, raw)
        end

        return nil if combined.empty?

        validator_module::Result.new(combined, config)
      end

      # Build result for a standard validator (single or multi-parser)
      # Auto-detects multi-parser validators by discovering parser classes
      # @param validator_module [Module] validator namespace module
      # @param validator_cfg [Class] validator config class
      # @param raw [Hash] raw results
      # @return [Results::Base, nil] result or nil
      def build_standard_result(validator_module, validator_cfg, raw)
        return nil unless raw[validator_cfg.id]

        stdout = raw.dig(validator_cfg.id, :stdout)
        return nil unless stdout

        # Discover all parser classes in the validator module
        parsers = discover_parsers(validator_module)
        return nil if parsers.empty?

        # Parse output with all parsers (single or multiple)
        parsed = parsers.flat_map { |parser| parser.new.call(stdout) }
        return nil if parsed.nil? || parsed.empty?

        validator_module::Result.new(parsed, config)
      end

      # Parse output from a validator module
      # @param validator_module [Module] validator namespace module
      # @param validator_cfg [Class] validator config class
      # @param raw [Hash] raw results
      # @return [Array<Hash>] parsed offenses
      def parse_validator_output(validator_module, validator_cfg, raw)
        return [] unless raw[validator_cfg.id]

        stdout = raw.dig(validator_cfg.id, :stdout)
        return [] unless stdout

        parsers = discover_parsers(validator_module)
        parsers.flat_map do |parser|
          parser_instance = parser.new
          # Try passing config to parser if it accepts it (for filtering)
          # Otherwise, call without config for backwards compatibility
          begin
            parser_instance.call(stdout, config: config)
          rescue ArgumentError
            parser_instance.call(stdout)
          end
        end
      end

      # Auto-discover parser classes in a validator module
      # Finds all classes that inherit from Parsers::Base
      # @param validator_module [Module] validator module to search
      # @return [Array<Class>] array of parser classes
      def discover_parsers(validator_module)
        validator_module.constants
                        .map { |const_name| validator_module.const_get(const_name) }
                        .select { |const| const.is_a?(Class) }
                        .select { |klass| klass < Parsers::Base }
                        .reject do |klass|
          [validator_module::Validator, validator_module::Result].include?(klass)
        end
      end
    end
  end
end
