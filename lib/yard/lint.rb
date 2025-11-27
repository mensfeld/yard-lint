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
        # Determine the base directory for relative path calculations
        base_dir = determine_base_dir(path)

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
        git_files.reject { |file| excluded_file?(file, config.exclude, base_dir) }
      end

      # Expand path/glob patterns into an array of files
      # @param path [String, Array<String>] path or array of paths
      # @param config [Yard::Lint::Config] configuration object
      # @return [Array<String>] array of absolute file paths
      def expand_path(path, config)
        # Determine the base directory for relative path calculations
        base_dir = determine_base_dir(path)

        files = discover_ruby_files(path)

        # Convert to absolute paths for YARD
        files = files.map { |file| File.expand_path(file) }

        # Filter out excluded files
        files.reject { |file| excluded_file?(file, config.exclude, base_dir) }
      end

      # Discover Ruby files from path/glob patterns
      # @param path [String, Array<String>] path or array of paths
      # @return [Array<String>] array of discovered Ruby file paths
      def discover_ruby_files(path)
        files = Array(path).flat_map do |p|
          if p.include?('*')
            Dir.glob(p)
          elsif File.directory?(p)
            Dir.glob(File.join(p, '**/*.rb'))
          else
            p
          end
        end

        files.select { |file| File.file?(file) && file.end_with?('.rb') }
      end

      # Determine base directory for relative path calculations
      # @param path [String, Array<String>] path or array of paths
      # @return [String] absolute base directory path
      def determine_base_dir(path)
        first_path = Array(path).first
        return Dir.pwd unless first_path

        absolute_path = File.expand_path(first_path)
        File.directory?(absolute_path) ? absolute_path : File.dirname(absolute_path)
      end

      # Check if a file matches any exclusion pattern
      # Patterns are matched against both absolute and relative paths
      # @param file [String] absolute file path
      # @param patterns [Array<String>] exclusion patterns
      # @param base_dir [String] base directory for relative path calculation
      # @return [Boolean] true if file should be excluded
      def excluded_file?(file, patterns, base_dir)
        relative_path = relative_path_from(file, base_dir)

        patterns.any? do |pattern|
          match_path?(pattern, file, relative_path)
        end
      end

      # Calculate relative path from base directory
      # @param file [String] absolute file path
      # @param base_dir [String] base directory
      # @return [String] relative path
      def relative_path_from(file, base_dir)
        if file.start_with?("#{base_dir}/")
          file.sub("#{base_dir}/", '')
        else
          file
        end
      end

      # Check if a pattern matches a file path
      # Tries matching against both relative and absolute paths
      # @param pattern [String] glob pattern
      # @param absolute_path [String] absolute file path
      # @param relative_path [String] relative file path
      # @return [Boolean] true if pattern matches
      def match_path?(pattern, absolute_path, relative_path)
        flags = File::FNM_PATHNAME | File::FNM_EXTGLOB

        File.fnmatch(pattern, relative_path, flags) || File.fnmatch(pattern, absolute_path, flags)
      end
    end
  end
end
