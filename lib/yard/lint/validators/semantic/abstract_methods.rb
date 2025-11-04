# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Semantic
      # AbstractMethods validator module
        module AbstractMethods
          class << self
            # Unique identifier for this validator
            # @return [Symbol] validator identifier
            def id
              :abstract_methods
            end

            # Default configuration for this validator
            # @return [Hash] default configuration
            def defaults
              {
                'Enabled' => true,
                'Severity' => 'warning',
                'AllowedImplementations' => [
                  'raise NotImplementedError',
                  'raise NotImplementedError, ".+"'
                ]
              }
            end
          end
        end
      end
    end
  end
end
