# frozen_string_literal: true

require 'zeitwerk'
require_relative 'lint/version'

# Define modules first
module Yard
  # YARD Lint module providing linting functionality for YARD documentation
  module Lint
    # Custom error class for YARD Lint exceptions
    class Error < StandardError; end
  end
end

# Setup Zeitwerk loader from lib directory
loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path('..', __dir__)) # Points to lib/
loader.ignore("#{__dir__}/lint/version.rb") # Manually required above
loader.setup

module Yard
  module Lint
    # Main entry point for running YARD lint
    # @param path [String, Array<String>] file or glob pattern to check
    # @param config [Yard::Lint::Config, nil] configuration object
    # @param config_file [String, nil] path to config file (auto-loads .yard-lint.yml if not specified)
    # @return [Yard::Lint::Result] result object with offenses
    def self.run(path:, config: nil, config_file: nil)
      config ||= load_config(config_file)
      files = expand_path(path, config)
      Runner.new(files, config).run
    end

    # Load configuration from file or auto-detect
    # @param config_file [String, nil] path to config file
    # @return [Yard::Lint::Config] configuration object
    def self.load_config(config_file)
      if config_file
        Config.from_file(config_file)
      else
        Config.load || Config.new
      end
    end

    # Expand path/glob patterns into an array of files
    # @param path [String, Array<String>] path or array of paths
    # @param config [Yard::Lint::Config] configuration object
    # @return [Array<String>] array of file paths
    def self.expand_path(path, config)
      files = Array(path).flat_map do |p|
        if p.include?('*')
          Dir.glob(p)
        elsif File.directory?(p)
          Dir.glob(File.join(p, '**/*.rb'))
        else
          p
        end
      end

      files = files.select { |f| File.file?(f) && f.end_with?('.rb') }

      # Filter out excluded files
      files.reject do |file|
        config.exclude.any? { |pattern| File.fnmatch(pattern, file, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
      end
    end
  end
end
