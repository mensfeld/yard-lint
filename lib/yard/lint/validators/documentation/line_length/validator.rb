# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module LineLength
          # Validates that documentation comment lines do not exceed the configured maximum length.
          #
          # Uses YARD's `docstring.line_range` to locate the exact source lines belonging to
          # each docstring block. This handles block comments, wrapped tag descriptions, and
          # macro expansion correctly — no arithmetic reconstruction needed.
          class Validator < Validators::Base
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.file && File.exist?(object.file)
              return if object.docstring.all.empty?

              line_range = object.docstring.line_range
              return unless line_range

              max_length = config_or_default('MaxLength').to_i
              source_lines = cached_lines(object.file)

              violations = []
              line_range.each do |line_no|
                raw_line = source_lines[line_no - 1].to_s.rstrip
                next if raw_line.length <= max_length

                violations << "#{line_no}:#{raw_line.length}"
              end

              return if violations.empty?

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts "#{max_length}|#{violations.join('|')}"
            end

            private

            # Returns the lines of a source file, reading from disk only on the first call
            # for each unique path.
            # @param file [String] absolute path to the source file
            # @return [Array<String>] lines of the file, memoized per path
            def cached_lines(file)
              @file_cache ||= {}
              @file_cache[file] ||= File.readlines(file)
            end
          end
        end
      end
    end
  end
end
