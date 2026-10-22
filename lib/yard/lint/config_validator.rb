# frozen_string_literal: true

module Yard
  module Lint
    # Validates configuration structure and values to catch typos and invalid settings
    class ConfigValidator
      # @param raw_config [Hash] raw configuration hash to validate
      def initialize(raw_config)
        @raw_config = raw_config
      end

      # Validate configuration and raise error if invalid
      # @param raw_config [Hash] raw configuration hash to validate
      # @return [void]
      # @raise [Errors::InvalidConfigError] if configuration is invalid
      def self.validate!(raw_config)
        validator = new(raw_config)
        validator.validate!
      end

      # Perform validation
      # @return [void]
      # @raise [Errors::InvalidConfigError] if configuration is invalid
      def validate!
        result = Contracts::Config.new.call(@raw_config)

        return if result.success?

        raise Errors::InvalidConfigError, build_error_message(result.errors.values)
      end

      private

      # Build comprehensive error message
      # @param messages [Array<String>] error messages, each one or more lines
      # @return [String] error message with one indented line per error line
      def build_error_message(messages)
        header = 'Invalid configuration detected:'
        errors_text = messages.flat_map { |message| message.split("\n") }.map { |e| "  #{e}" }.join("\n")

        "#{header}\n#{errors_text}"
      end
    end
  end
end
