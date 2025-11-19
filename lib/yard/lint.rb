# frozen_string_literal: true

require 'yaml'
require 'shellwords'
require 'open3'
require 'tempfile'
require 'tmpdir'
require 'digest'
require 'did_you_mean'
require 'yard'

module Yard
  # YARD Lint module providing linting functionality for YARD documentation
  module Lint
    class << self
      # Main entry point for running YARD lint
      # @param path [String, Array<String>] file or glob pattern to check
      # @param config [Yard::Lint::Config, nil] configuration object
      # @param config_file [String, nil] path to config file
      #   (auto-loads .yard-lint.yml if not specified)
      # @param progress [Boolean] show progress indicator (default: true for TTY)
      # @param diff [Hash, nil] diff mode options
      #   - :mode [Symbol] one of :ref, :staged, :changed
      #   - :base_ref [String, nil] base ref for :ref mode (auto-detects main/master if nil)
      # @return [Yard::Lint::Result] result object with offenses
      def run(path:, config: nil, config_file: nil, progress: nil, diff: nil)
        config ||= load_config(config_file)

        # Determine files to lint based on diff mode or normal path expansion
        files = if diff
                  get_diff_files(diff, path, config)
                else
                  expand_path(path, config)
                end

        runner = Runner.new(files, config)

        # Enable progress by default if output is a TTY
        show_progress = progress.nil? ? $stdout.tty? : progress
        runner.progress_formatter = Formatters::Progress.new if show_progress

        runner.run
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

      # Get files from git diff based on diff mode
      # @param diff [Hash] diff mode options
      # @param path [String, Array<String>] path or array of paths to filter within
      # @param config [Yard::Lint::Config] configuration object
      # @return [Array<String>] array of absolute file paths
      def get_diff_files(diff, path, config)
        # Get changed files from git based on mode
        git_files = case diff[:mode]
                    when :ref
                      Git.changed_files(diff[:base_ref], path)
                    when :staged
                      Git.staged_files(path)
                    when :changed
                      Git.uncommitted_files(path)
                    else
                      raise ArgumentError, "Unknown diff mode: #{diff[:mode]}"
                    end

        # Apply exclusion patterns
        git_files.reject do |file|
          config.exclude.any? do |pattern|
            File.fnmatch(pattern, file, File::FNM_PATHNAME | File::FNM_EXTGLOB)
          end
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
