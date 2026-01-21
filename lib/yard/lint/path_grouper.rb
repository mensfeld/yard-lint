# frozen_string_literal: true

module Yard
  module Lint
    # Groups file paths into patterns when beneficial
    class PathGrouper
      # Coverage threshold for directory-level grouping (80%)
      DIRECTORY_COVERAGE_THRESHOLD = 0.8

      class << self
        # Group file paths into patterns
        # @param files [Array<String>] array of file paths
        # @param limit [Integer] minimum files to trigger grouping (default: 15)
        # @return [Array<String>] array of paths or patterns
        def group(files, limit: 15)
          return files.uniq.sort if files.size < limit

          grouped = find_common_directories(files, limit)
          grouped.sort
        end

        private

        # Find directories where files can be grouped into patterns
        # @param files [Array<String>] unique file paths to analyze
        # @param limit [Integer] minimum file count threshold for grouping
        # @return [Array<String>] array of file paths or directory patterns
        def find_common_directories(files, limit)
          # Deduplicate files first
          unique_files = files.uniq
          by_dir = unique_files.group_by { |f| File.dirname(f) }
          result = []

          by_dir.each do |dir, dir_files|
            if should_group_directory?(dir, dir_files.uniq, limit)
              result << "#{dir}/**/*"
            else
              result.concat(dir_files.uniq)
            end
          end

          result.uniq
        end

        # Determine if a directory should be grouped
        # @param dir [String] directory path to evaluate
        # @param dir_files [Array<String>] files in this directory
        # @param limit [Integer] minimum file count threshold
        # @return [Boolean] true if directory should be grouped into pattern
        def should_group_directory?(dir, dir_files, limit)
          # Must have enough files and more than just one file
          return false if dir_files.size < limit || dir_files.size == 1

          # Check coverage: do we have most Ruby files in this directory?
          begin
            all_ruby_files = Dir.glob("#{dir}/**/*.rb")
            # Don't group if directory doesn't exist or is empty
            return false if all_ruby_files.empty?

            coverage = dir_files.size.to_f / all_ruby_files.size
            coverage >= DIRECTORY_COVERAGE_THRESHOLD
          rescue StandardError
            # If glob fails (directory doesn't exist), don't group
            false
          end
        end
      end
    end
  end
end
