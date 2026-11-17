# frozen_string_literal: true

module Yard
  module Lint
    module Formatters
      # Shortens offense locations for display
      module RelativePath
        class << self
          # Path relative to base_dir when the file is inside it. A path outside
          # base_dir keeps its original value rather than becoming a `../` path.
          # @param location [String, nil] the offense location path
          # @param base_dir [String] directory the path is made relative to
          # @return [String] a relative path where possible
          def call(location, base_dir = Dir.pwd)
            path = location.to_s
            return path if path.empty?

            base = File.absolute_path(base_dir)
            absolute = File.absolute_path(path, base)
            return absolute.delete_prefix("#{base}/") if absolute.start_with?("#{base}/")

            relative = Pathname.new(absolute).relative_path_from(Pathname.new(base)).to_s
            relative.start_with?('..') ? path : relative
          rescue ArgumentError
            # relative_path_from raises across platforms/mixed roots; fall back.
            path
          end
        end
      end
    end
  end
end
