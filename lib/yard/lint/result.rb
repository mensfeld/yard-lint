# frozen_string_literal: true

module Yard
  module Lint
    # Result object containing all offenses found during validation
    class Result
      attr_reader :warnings, :undocumented, :undocumented_method_arguments,
                  :invalid_tags_types, :invalid_tags_order, :api_tags,
                  :abstract_methods, :option_tags, :config

      # Severity levels for different offense types
      # @return [String] severity level for errors
      SEVERITY_ERROR = 'error'
      # @return [String] severity level for warnings
      SEVERITY_WARNING = 'warning'
      # @return [String] severity level for conventions
      SEVERITY_CONVENTION = 'convention'

      # @param data [Hash] parsed data from validators
      # @param config [Yard::Lint::Config, nil] configuration object for severity lookup
      def initialize(data, config = nil)
        @warnings = data[:warnings] || []
        @undocumented = data[:undocumented] || []
        @undocumented_method_arguments = data[:undocumented_method_arguments] || []
        @invalid_tags_types = data[:invalid_tags_types] || []
        @invalid_tags_order = data[:invalid_tags_order] || []
        @api_tags = data[:api_tags] || []
        @abstract_methods = data[:abstract_methods] || []
        @option_tags = data[:option_tags] || []
        @config = config
      end

      # Returns all offenses as a flat array
      # @return [Array<Hash>] array of all offenses with consistent structure
      def offenses
        [
          *build_warning_offenses,
          *build_undocumented_offenses,
          *build_undocumented_method_arguments_offenses,
          *build_invalid_tags_types_offenses,
          *build_invalid_tags_order_offenses,
          *build_api_tags_offenses,
          *build_abstract_methods_offenses,
          *build_option_tags_offenses
        ]
      end

      # Returns count of offenses
      # @return [Integer] total offense count
      def count
        offenses.count
      end

      # Returns true if there are any offenses
      # @return [Boolean] whether there are offenses
      def offenses?
        count.positive?
      end

      # Returns true if there are no offenses
      # @return [Boolean] whether the code is clean
      def clean?
        !offenses?
      end

      # Returns statistics about offenses by severity
      # @return [Hash] hash with counts by severity level
      def statistics
        stats = {
          error: 0,
          warning: 0,
          convention: 0,
          total: 0
        }

        offenses.each do |offense|
          severity = offense[:severity].to_sym
          stats[severity] += 1 if stats.key?(severity)
          stats[:total] += 1
        end

        stats
      end

      # Determine exit code based on configuration
      # @param config [Yard::Lint::Config] configuration object
      # @return [Integer] exit code (0 for success, 1 for failure)
      def exit_code(config)
        return 0 if clean?
        return 0 if config.fail_on_severity == 'never'

        case config.fail_on_severity
        when 'error'
          offenses.any? { |o| o[:severity] == SEVERITY_ERROR } ? 1 : 0
        when 'warning'
          offenses.any? { |o| [SEVERITY_ERROR, SEVERITY_WARNING].include?(o[:severity]) } ? 1 : 0
        when 'convention'
          offenses.any? ? 1 : 0
        else
          1
        end
      end

      private

      # Build warning offenses (errors)
      # @return [Array<Hash>] array of warning offenses
      def build_warning_offenses
        warnings.map do |warning|
          # Map warning name to validator name for severity lookup
          validator_name = warning_name_to_validator(warning[:name])
          severity = configured_severity(validator_name, SEVERITY_ERROR)

          {
            severity: severity,
            type: 'line',
            name: warning[:name],
            message: warning[:message],
            location: warning[:location],
            location_line: warning[:line]
          }
        end
      end

      # Build undocumented offenses (warnings)
      # @return [Array<Hash>] array of undocumented offenses
      def build_undocumented_offenses
        undocumented.map do |offense|
          severity = configured_severity('Documentation/UndocumentedObjects', SEVERITY_WARNING)

          {
            severity: severity,
            type: 'line',
            name: 'UndocumentedObject',
            message: Validators::Documentation::UndocumentedObjects::MessagesBuilder.call(offense),
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build undocumented method arguments offenses (warnings)
      # @return [Array<Hash>] array of undocumented method arguments offenses
      def build_undocumented_method_arguments_offenses
        severity = configured_severity('Documentation/UndocumentedMethodArguments', SEVERITY_WARNING)

        undocumented_method_arguments.map do |offense|
          {
            severity: severity,
            type: 'method',
            name: 'UndocumentedMethodArgument',
            message: Validators::Documentation::UndocumentedMethodArguments::MessagesBuilder.call(offense),
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build invalid tags types offenses (warnings)
      # @return [Array<Hash>] array of invalid tags types offenses
      def build_invalid_tags_types_offenses
        severity = configured_severity('Tags/InvalidTypes', SEVERITY_WARNING)

        invalid_tags_types.map do |offense|
          {
            severity: severity,
            type: 'method',
            name: 'InvalidTagType',
            message: Validators::Tags::InvalidTypes::MessagesBuilder.call(offense),
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build invalid tags order offenses (conventions)
      # @return [Array<Hash>] array of invalid tags order offenses
      def build_invalid_tags_order_offenses
        severity = configured_severity('Tags/Order', SEVERITY_CONVENTION)

        invalid_tags_order.map do |offense|
          {
            severity: severity,
            type: 'method',
            name: 'InvalidTagsOrder',
            message: Validators::Tags::Order::MessagesBuilder.call(offense),
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build API tag offenses (warnings)
      # @return [Array<Hash>] array of API tag offenses
      def build_api_tags_offenses
        severity = configured_severity('Tags/ApiTags', SEVERITY_WARNING)

        api_tags.map do |offense|
          {
            severity: severity,
            type: 'line',
            name: offense[:name],
            message: Validators::Tags::ApiTags::MessagesBuilder.call(offense),
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build abstract method offenses (warnings)
      # @return [Array<Hash>] array of abstract method offenses
      def build_abstract_methods_offenses
        severity = configured_severity('Semantic/AbstractMethods', SEVERITY_WARNING)

        abstract_methods.map do |offense|
          {
            severity: severity,
            type: 'method',
            name: offense[:name],
            message: Validators::Semantic::AbstractMethods::MessagesBuilder.call(offense),
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build option tag offenses (warnings)
      # @return [Array<Hash>] array of option tag offenses
      def build_option_tags_offenses
        severity = configured_severity('Tags/OptionTags', SEVERITY_WARNING)

        option_tags.map do |offense|
          {
            severity: severity,
            type: 'method',
            name: offense[:name],
            message: Validators::Tags::OptionTags::MessagesBuilder.call(offense),
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Get configured severity or default
      # @param validator_name [String] full validator name
      # @param default [String] default severity if config not available
      # @return [String] severity level
      def configured_severity(validator_name, default)
        return default unless config

        config.validator_severity(validator_name)
      end

      # Map warning name to validator name
      # @param name [String] warning name (e.g., 'UnknownTag')
      # @return [String] validator name (e.g., 'Warnings/UnknownTag')
      def warning_name_to_validator(name)
        "Warnings/#{name}"
      end
    end
  end
end
