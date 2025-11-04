# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
      # UndocumentedBooleanMethods validator module
        module UndocumentedBooleanMethods
          class << self
            # Unique identifier for this validator
            # @return [Symbol] validator identifier
            def id
              :undocumented_boolean_methods
            end

            # Default configuration for this validator
            # @return [Hash] default configuration
            def defaults
              {
                'Enabled' => true,
                'Severity' => 'warning'
              }
            end
          end
        end
      end
    end
  end
end
