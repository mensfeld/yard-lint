# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module LineLength
          # Validates that documentation comment lines do not exceed the configured maximum length.
          #
          # Uses YARD's already-parsed docstring to determine the exact set of lines that
          # belong to a docstring block. The line count from the parsed docstring is used to
          # derive the absolute source line positions, so no manual backwards-scanning is needed.
          class Validator < Validators::Base
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.file && File.exist?(object.file)
              return unless object.line.to_i > 0
              return if object.docstring.all.empty?

              max_length = config_or_default('MaxLength').to_i
              docstring_text = object.docstring.all
              docstring_line_count = docstring_text.split("\n", -1).size

              # The docstring comment block occupies the lines immediately above
              # object.line in the source file. YARD has already parsed the exact
              # docstring content, so we trust its line count to locate the block.
              source_lines = File.readlines(object.file)
              definition_idx = object.line - 1
              doc_start_idx = definition_idx - docstring_line_count

              return if doc_start_idx < 0

              violations = []
              docstring_line_count.times do |i|
                source_idx = doc_start_idx + i
                raw_line = source_lines[source_idx].to_s.rstrip
                next if raw_line.length <= max_length

                violations << "#{source_idx + 1}:#{raw_line.length}"
              end

              return if violations.empty?

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts violations.join('|')
            end
          end
        end
      end
    end
  end
end
