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

      # Raised when a specified file or directory does not exist
      class FileNotFoundError < BaseError; end

      # Raised when .yard-lint-todo.yml already exists without force flag
      class TodoFileExistsError < BaseError; end

      # Raised when configuration is invalid
      class InvalidConfigError < BaseError; end
    end
  end
end
