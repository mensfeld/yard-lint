# frozen_string_literal: true

module Yard
  module Lint
    # Validators for checking different aspects of YARD documentation
    module Validators
      # Base YARD validator class
      class Base
        # Class-level settings for in-process execution
        # These must be set on each subclass, not on Base
        @in_process_enabled = nil
        @in_process_visibility = nil

        attr_reader :config, :selection

        class << self
          # Declare that this validator supports in-process execution
          # @param visibility [Symbol] visibility filter for objects (:public or :all)
          #   :public - only include public methods (default, no --private/--protected)
          #   :all - include all methods (equivalent to --private --protected)
          # @return [void]
          # @example
          #   class Validator < Base
          #     in_process visibility: :all
          #   end
          def in_process(visibility: :public)
            @in_process_enabled = true
            @in_process_visibility = visibility
          end

          # Check if this validator supports in-process execution
          # @return [Boolean]
          def in_process?
            @in_process_enabled == true
          end

          # Get the visibility setting for in-process execution
          # @return [Symbol, nil] :public, :all, or nil if not set
          def in_process_visibility
            @in_process_visibility
          end

          # Get the validator name from the class namespace
          # @return [String, nil] validator name like 'Tags/Order' or nil
          # @example
          #   Yard::Lint::Validators::Tags::Order::Validator.validator_name
          #   # => 'Tags/Order'
          def validator_name
            name&.split('::')&.then do |parts|
              idx = parts.index('Validators')
              return nil unless idx && parts[idx + 1] && parts[idx + 2]

              "#{parts[idx + 1]}/#{parts[idx + 2]}"
            end
          end
        end

        # @param config [Yard::Lint::Config] configuration object
        # @param selection [Array<String>] array with ruby files we want to check
        def initialize(config, selection)
          @config = config
          @selection = selection
        end

        # Execute query for a single object during in-process execution.
        # Override this method in validators that support in-process execution.
        # @param object [YARD::CodeObjects::Base] the code object to query
        # @param collector [Executor::ResultCollector] collector for output
        # @return [void]
        # @example
        #   def in_process_query(object, collector)
        #     return unless object.docstring.all.empty?
        #     collector.puts "#{object.file}:#{object.line}: #{object.title}"
        #   end
        def in_process_query(object, collector)
          raise NotImplementedError, "#{self.class} must implement in_process_query for in-process execution"
        end

        private

        # Retrieves configuration value with fallback to default
        # Automatically determines the validator name from the class namespace
        #
        # @param key [String] the configuration key to retrieve
        # @return [Object] the configured value or default value from the validator's Config.defaults
        # @example Usage in a validator (e.g., Tags::RedundantParamDescription)
        #   def config_articles
        #     config_or_default("Articles")
        #   end
        # @note The validator name is automatically extracted from the class namespace.
        #   For example, Yard::Lint::Validators::Tags::RedundantParamDescription::Validator
        #   becomes 'Tags/RedundantParamDescription'
        def config_or_default(key)
          validator_name = self.class.name&.split('::')&.then do |parts|
            idx = parts.index('Validators')
            next nil unless idx && parts[idx + 1] && parts[idx + 2]

            "#{parts[idx + 1]}/#{parts[idx + 2]}"
          end

          # Get the validator module's Config class
          validator_config_class = begin
            # Get parent module (e.g., Yard::Lint::Validators::Tags::RedundantParamDescription)
            parent_module = self.class.name.split('::')[0..-2].join('::')
            Object.const_get("#{parent_module}::Config")
          rescue NameError
            nil
          end

          defaults = validator_config_class&.defaults || {}

          return defaults[key] unless validator_name

          config.validator_config(validator_name, key) || defaults[key]
        end
      end
    end
  end
end
