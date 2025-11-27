# frozen_string_literal: true

module Yard
  module Lint
    # Namespace for all yard-lint errors
    module Errors
      # Base error class for all yard-lint errors
      class BaseError < StandardError; end

      # Raised when a configuration file is not found
      class ConfigFileNotFoundError < BaseError; end

      # Raised when a circular dependency is detected in configuration inheritance
      class CircularDependencyError < BaseError; end

      # Raised when an unknown validator name is specified via --only
      class UnknownValidatorError < BaseError; end
    end
  end
end
