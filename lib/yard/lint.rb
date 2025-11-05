# frozen_string_literal: true

require 'yaml'
require 'shellwords'
require 'open3'
require 'tmpdir'
require 'digest'
require 'net/http'
require 'uri'

module Yard
  # YARD Lint module providing linting functionality for YARD documentation
  module Lint
    class << self
      # Main entry point for running YARD lint
      # @param path [String, Array<String>] file or glob pattern to check
      # @param config [Yard::Lint::Config, nil] configuration object
      # @param config_file [String, nil] path to config file
      #   (auto-loads .yard-lint.yml if not specified)
      # @return [Yard::Lint::Result] result object with offenses
      def run(path:, config: nil, config_file: nil)
        config ||= load_config(config_file)
        files = expand_path(path, config)
        Runner.new(files, config).run
      end

      private

      # Load configuration from file or auto-detect
      # @param config_file [String, nil] path to config file
      # @return [Yard::Lint::Config] configuration object
      def load_config(config_file)
        if config_file
          Config.from_file(config_file)
        else
          Config.load || Config.new
        end
      end

      # Expand path/glob patterns into an array of files
      # @param path [String, Array<String>] path or array of paths
      # @param config [Yard::Lint::Config] configuration object
      # @return [Array<String>] array of absolute file paths
      def expand_path(path, config)
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

        # Convert to absolute paths for YARD
        files = files.map { |f| File.expand_path(f) }

        # Filter out excluded files
        files.reject do |file|
          config.exclude.any? do |pattern|
            File.fnmatch(pattern, file, File::FNM_PATHNAME | File::FNM_EXTGLOB)
          end
        end
      end
    end
  end
end
