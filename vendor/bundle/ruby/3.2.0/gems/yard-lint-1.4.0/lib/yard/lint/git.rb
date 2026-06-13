# frozen_string_literal: true

module Yard
  module Lint
    # Git integration for diff mode functionality
    module Git
      # Custom error class for Git-related errors
      class Error < StandardError; end

      class << self
        # Detect the default branch (main or master)
        # @return [String] 'main', 'master', or nil if neither exists
        def default_branch
          # Try main first (modern default)
          return 'main' if branch_exists?('main')
          # Fall back to master (legacy default)
          return 'master' if branch_exists?('master')

          nil
        end

        # Check if a git ref exists
        # @param ref [String] the git ref to check
        # @return [Boolean] true if ref exists
        def branch_exists?(ref)
          _stdout, _stderr, status = Open3.capture3('git', 'rev-parse', '--verify', '--quiet', ref)
          status.success?
        end

        # Get files changed since a base ref
        # @param base_ref [String, nil] the base ref to compare against (nil for auto-detect)
        # @param path [String] the path to filter files within
        # @return [Array<String>] absolute paths to changed Ruby files
        def changed_files(base_ref, path)
          base_ref ||= default_branch
          raise Error, 'Could not detect default branch (main/master)' unless base_ref

          ensure_git_repository!

          # Use three-dot diff to compare against merge base
          stdout, stderr, status = Open3.capture3('git', 'diff', '--name-only', "#{base_ref}...HEAD")

          unless status.success?
            raise Error, "Git diff failed: #{stderr.strip}"
          end

          filter_ruby_files(stdout.split("\n"), path)
        end

        # Get staged files (files in git index)
        # @param path [String] the path to filter files within
        # @return [Array<String>] absolute paths to staged Ruby files
        def staged_files(path)
          ensure_git_repository!

          # ACM filter: Added, Copied, Modified (exclude Deleted)
          stdout, stderr, status = Open3.capture3(
            'git', 'diff', '--cached', '--name-only', '--diff-filter=ACM'
          )

          unless status.success?
            raise Error, "Git diff failed: #{stderr.strip}"
          end

          filter_ruby_files(stdout.split("\n"), path)
        end

        # Get uncommitted files (all changes in working directory)
        # @param path [String] the path to filter files within
        # @return [Array<String>] absolute paths to uncommitted Ruby files
        def uncommitted_files(path)
          ensure_git_repository!

          # Get both staged and unstaged changes
          stdout, stderr, status = Open3.capture3('git', 'diff', '--name-only', 'HEAD')

          unless status.success?
            raise Error, "Git diff failed: #{stderr.strip}"
          end

          filter_ruby_files(stdout.split("\n"), path)
        end

        private

        # Ensure we're in a git repository
        # @raise [Error] if not in a git repository
        def ensure_git_repository!
          _stdout, _stderr, status = Open3.capture3('git', 'rev-parse', '--git-dir')

          return if status.success?

          raise Error, 'Not a git repository'
        end

        # Filter for Ruby files within path and convert to absolute paths
        # @param files [Array<String>] relative file paths from git
        # @param path [String] the base path to filter within
        # @return [Array<String>] absolute paths to Ruby files that exist
        def filter_ruby_files(files, path)
          base_path = File.expand_path(path)

          files
            .select { |f| f.end_with?('.rb') }
            .map { |f| File.expand_path(f) }
            .select { |f| File.exist?(f) } # Skip deleted files
            .select { |f| file_within_path?(f, base_path) }
        end

        # Check if file is within the specified path
        # @param file [String] absolute file path
        # @param base_path [String] absolute base path
        # @return [Boolean] true if file is within base_path
        def file_within_path?(file, base_path)
          # Handle both directory and file base_path
          if File.directory?(base_path)
            file.start_with?(base_path + '/')
          else
            file == base_path
          end
        end
      end
    end
  end
end
