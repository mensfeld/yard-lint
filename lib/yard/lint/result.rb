# frozen_string_literal: true

module Yard
  module Lint
    # Result object containing all offenses found during validation
    class Result
      attr_reader :warnings, :undocumented, :undocumented_method_arguments,
        :invalid_tags_types, :invalid_tags_order, :api_tags,
        :abstract_methods, :option_tags

      # Severity levels for different offense types
      # @return [String] severity level for errors
      SEVERITY_ERROR = 'error'
      # @return [String] severity level for warnings
      SEVERITY_WARNING = 'warning'
      # @return [String] severity level for conventions
      SEVERITY_CONVENTION = 'convention'

      # @param data [Hash] parsed data from validators
      def initialize(data)
        @warnings = data[:warnings] || []
        @undocumented = data[:undocumented] || []
        @undocumented_method_arguments = data[:undocumented_method_arguments] || []
        @invalid_tags_types = data[:invalid_tags_types] || []
        @invalid_tags_order = data[:invalid_tags_order] || []
        @api_tags = data[:api_tags] || []
        @abstract_methods = data[:abstract_methods] || []
        @option_tags = data[:option_tags] || []
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
          {
            severity: SEVERITY_ERROR,
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
          {
            severity: SEVERITY_WARNING,
            type: 'line',
            name: 'UndocumentedObject',
            message: "Documentation required for `#{offense[:element]}`",
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build undocumented method arguments offenses (warnings)
      # @return [Array<Hash>] array of undocumented method arguments offenses
      def build_undocumented_method_arguments_offenses
        undocumented_method_arguments.map do |offense|
          {
            severity: SEVERITY_WARNING,
            type: 'method',
            name: 'UndocumentedMethodArgument',
            message: "The `#{offense[:method_name]}` method is missing documentation " \
                     'for some of the arguments.',
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build invalid tags types offenses (warnings)
      # @return [Array<Hash>] array of invalid tags types offenses
      def build_invalid_tags_types_offenses
        invalid_tags_types.map do |offense|
          {
            severity: SEVERITY_WARNING,
            type: 'method',
            name: 'InvalidTagType',
            message: "The `#{offense[:method_name]}` has at least one tag " \
                     'with an invalid type definition.',
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build invalid tags order offenses (conventions)
      # @return [Array<Hash>] array of invalid tags order offenses
      def build_invalid_tags_order_offenses
        invalid_tags_order.map do |offense|
          expected_order = offense[:order]
                           .to_s
                           .split(',')
                           .map { |tag| "`#{tag}`" }
                           .join(', ')

          {
            severity: SEVERITY_CONVENTION,
            type: 'method',
            name: 'InvalidTagsOrder',
            message: "The `#{offense[:method_name]}` has yard tags in an invalid order. " \
                     "Following tags need to be in the presented order: #{expected_order}.",
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build API tag offenses (warnings)
      # @return [Array<Hash>] array of API tag offenses
      def build_api_tags_offenses
        api_tags.map do |offense|
          {
            severity: SEVERITY_WARNING,
            type: 'line',
            name: offense[:name],
            message: offense[:message],
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build abstract method offenses (warnings)
      # @return [Array<Hash>] array of abstract method offenses
      def build_abstract_methods_offenses
        abstract_methods.map do |offense|
          {
            severity: SEVERITY_WARNING,
            type: 'method',
            name: offense[:name],
            message: offense[:message],
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end

      # Build option tag offenses (warnings)
      # @return [Array<Hash>] array of option tag offenses
      def build_option_tags_offenses
        option_tags.map do |offense|
          {
            severity: SEVERITY_WARNING,
            type: 'method',
            name: offense[:name],
            message: offense[:message],
            location: offense[:location],
            location_line: offense[:line]
          }
        end
      end
    end
  end
end
