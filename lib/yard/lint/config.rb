# frozen_string_literal: true

require 'yaml'

module Yard
  module Lint
    # Configuration object for YARD Lint
    class Config
      attr_accessor :options, :tags_order, :invalid_tags_names, :extra_types,
        :exclude, :fail_on_severity, :require_api_tags, :allowed_apis,
        :validate_abstract_methods, :validate_option_tags

      # Default YAML config file name
      DEFAULT_CONFIG_FILE = '.yard-lint.yml'

      # Default YARD options
      DEFAULT_OPTIONS = [].freeze

      # Default tags order (common YARD tag ordering)
      DEFAULT_TAGS_ORDER = %w[
        param
        option
        yield
        yieldparam
        yieldreturn
        return
        raise
        see
        example
        note
        todo
      ].freeze

      # Default tags to check for invalid types
      DEFAULT_INVALID_TAGS_NAMES = %w[
        param
        option
        return
        yieldreturn
      ].freeze

      # Default extra types that are allowed
      DEFAULT_EXTRA_TYPES = [].freeze

      # Default exclusion patterns (.git is always excluded)
      DEFAULT_EXCLUDE = ['\.git', 'vendor/**/*', 'node_modules/**/*'].freeze

      # Default fail severity level
      DEFAULT_FAIL_ON_SEVERITY = 'warning'

      # Valid severity levels for fail_on_severity
      VALID_SEVERITIES = %w[error warning convention never].freeze

      # Default allowed API values
      DEFAULT_ALLOWED_APIS = %w[public private internal].freeze

      def initialize
        @options = DEFAULT_OPTIONS.dup
        @tags_order = DEFAULT_TAGS_ORDER.dup
        @invalid_tags_names = DEFAULT_INVALID_TAGS_NAMES.dup
        @extra_types = DEFAULT_EXTRA_TYPES.dup
        @exclude = DEFAULT_EXCLUDE.dup
        @fail_on_severity = DEFAULT_FAIL_ON_SEVERITY
        @require_api_tags = false
        @allowed_apis = DEFAULT_ALLOWED_APIS.dup
        @validate_abstract_methods = true
        @validate_option_tags = true

        yield self if block_given?
      end

      # Load configuration from a YAML file
      # @param path [String] path to YAML config file
      # @return [Yard::Lint::Config] configuration object
      def self.from_file(path)
        raise ArgumentError, "Config file not found: #{path}" unless File.exist?(path)

        yaml = YAML.load_file(path)
        new do |config|
          config.options = yaml['options'] if yaml['options']
          config.tags_order = yaml['tags_order'] if yaml['tags_order']
          config.invalid_tags_names = yaml['invalid_tags_names'] if yaml['invalid_tags_names']
          config.extra_types = yaml['extra_types'] if yaml['extra_types']
          config.exclude = yaml['exclude'] if yaml['exclude']
          config.fail_on_severity = yaml['fail_on_severity'] if yaml['fail_on_severity']
          config.require_api_tags = yaml['require_api_tags'] if yaml.key?('require_api_tags')
          config.allowed_apis = yaml['allowed_apis'] if yaml['allowed_apis']
          if yaml.key?('validate_abstract_methods')
            config.validate_abstract_methods = yaml['validate_abstract_methods']
          end
          if yaml.key?('validate_option_tags')
            config.validate_option_tags = yaml['validate_option_tags']
          end
        end
      end

      # Search for and load config file from current directory upwards
      # @param start_path [String] directory to start searching from (default: current dir)
      # @return [Yard::Lint::Config, nil] config if found, nil otherwise
      def self.load(start_path: Dir.pwd)
        config_path = find_config_file(start_path)
        config_path ? from_file(config_path) : nil
      end

      # Find config file by searching upwards from start_path
      # @param start_path [String] directory to start searching from
      # @return [String, nil] path to config file if found
      def self.find_config_file(start_path)
        current = File.expand_path(start_path)
        root = File.expand_path('/')

        loop do
          config_path = File.join(current, DEFAULT_CONFIG_FILE)
          return config_path if File.exist?(config_path)

          break if current == root

          current = File.dirname(current)
        end

        nil
      end

      # Allow hash-like access for backward compatibility
      # @param key [Symbol, String] attribute name to access
      # @return [Object, nil] attribute value or nil if not found
      def [](key)
        respond_to?(key) ? send(key) : nil
      end
    end
  end
end
