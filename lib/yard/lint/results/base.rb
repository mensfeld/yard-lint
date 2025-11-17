# frozen_string_literal: true

module Yard
  module Lint
    module Results
      # Base class for validator-specific result objects
      # Each validator should subclass this and set class attributes
      #
      # @example Creating a validator result class
      #   class MyValidator::Result < Results::Base
      #     self.default_severity = 'warning'
      #     self.offense_type = 'method'
      #     self.offense_name = 'MyOffense'
      #
      #     def build_message(offense)
      #       "Found issue in #{offense[:location]}"
      #     end
      #   end
      class Base
        class << self
          # Default severity level for this validator's offenses
          # @return [String] 'error', 'warning', or 'convention'
          attr_writer :default_severity

          # Get the default severity level for this validator
          # @return [String] 'error', 'warning', or 'convention'
          def default_severity
            @default_severity ||
              (superclass.respond_to?(:default_severity) ? superclass.default_severity : nil)
          end

          # Type of offense for display purposes
          # @return [String] 'line' or 'method'
          attr_writer :offense_type

          # Get the offense type for this validator
          # @return [String] 'line' or 'method'
          def offense_type
            @offense_type ||
              (superclass.respond_to?(:offense_type) ? superclass.offense_type : nil)
          end

          # Name of the offense for identification
          # @return [String] offense name
          attr_writer :offense_name

          # Get the offense name for this validator
          # @return [String] offense name
          def offense_name
            @offense_name ||
              (superclass.respond_to?(:offense_name) ? superclass.offense_name : nil)
          end
        end

        # Set default values for base class
        self.offense_type = 'line'

        attr_accessor :offenses
        attr_reader :config

        # Initialize a result object with parsed validator data
        # @param parsed_data [Array<Hash>] Array of offense hashes from validator parser
        # @param config [Config, nil] Configuration object for severity lookup
        def initialize(parsed_data, config = nil)
          @parsed_data = Array(parsed_data)
          @config = config
          @offenses = build_offenses
        end

        # Count of offenses
        # @return [Integer] number of offenses
        def count
          @offenses.count
        end

        # Check if there are no offenses
        # @return [Boolean] true if no offenses
        def empty?
          @offenses.empty?
        end

        # Delegate array methods to offenses for convenience
        # @return [Array] mapped offenses
        def map(&)
          @offenses.map(&)
        end

        # Delegate each to offenses
        # @return [Array] offenses
        def each(&)
          @offenses.each(&)
        end

        # Full validator name in format 'Category/ValidatorName'
        # Extracted from the class path
        # @return [String] validator name for config lookup
        def validator_name
          # Extract from class path: Validators::Tags::Order::Result => 'Tags/Order'
          parts = self.class.name.split('::')
          validators_index = parts.index('Validators')
          return '' unless validators_index

          category = parts[validators_index + 1]
          name = parts[validators_index + 2]
          "#{category}/#{name}"
        end

        private

        # Build a human-readable message for an offense
        # Subclasses must override this method
        # @param offense [Hash] offense data from parser
        # @return [String] formatted message
        def build_message(offense)
          raise NotImplementedError, "#{self.class} must implement #build_message"
        end

        # Build array of offense hashes in unified format
        # Merges original parsed data with standard offense fields
        # @return [Array<Hash>] array of offense hashes
        def build_offenses
          @parsed_data.map do |offense_data|
            # Start with original parsed data to preserve all fields
            offense_data.merge(
              severity: configured_severity,
              type: self.class.offense_type,
              name: computed_offense_name,
              message: build_message(offense_data),
              location: offense_data[:location] || offense_data[:file],
              location_line: offense_data[:line] || offense_data[:location_line] || 0
            )
          end
        end

        # Get configured severity or fall back to default
        # @return [String] severity level
        def configured_severity
          default = self.class.default_severity
          raise NotImplementedError, "#{self.class} must set self.default_severity" unless default

          return default unless config

          config.validator_severity(validator_name) || default
        end

        # Compute offense name from class attribute or derive from class name
        # @return [String] offense name
        def computed_offense_name
          return self.class.offense_name if self.class.offense_name
          return 'Unknown' unless self.class.name

          self.class.name.split('::').last.sub(/Result$/, '')
        end
      end
    end
  end
end
