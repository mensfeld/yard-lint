# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Base configuration class for validators
      # Provides common class attributes for all validators
      class Config
        class << self
          # Unique identifier for this validator
          # @return [Symbol] validator identifier
          attr_accessor :id

          # Default configuration for this validator
          # @return [Hash] default configuration hash
          attr_accessor :defaults

          # Validators to combine with this one
          # @return [Array<String>] validator names to combine, empty array for standalone
          def combines_with
            @combines_with ||= []
          end

          # Set validators to combine with
          attr_writer :combines_with
        end
      end
    end
  end
end
