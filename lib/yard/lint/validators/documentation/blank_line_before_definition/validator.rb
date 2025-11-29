# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module BlankLineBeforeDefinition
          # Validates blank lines between documentation and definitions
          class Validator < Validators::Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Checks for blank lines between documentation blocks and definitions.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.file && File.exist?(object.file) && object.line.to_i > 1

              source_lines = File.readlines(object.file)
              definition_line = object.line - 1

              blank_count, has_doc_block = analyze_spacing(source_lines, definition_line)

              return if blank_count.zero? || !has_doc_block

              violation_type = blank_count >= 2 ? 'orphaned' : 'single'

              return unless pattern_enabled?(violation_type)

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts "#{violation_type}:#{blank_count}"
            end

            private

            # Analyze spacing between documentation and definition
            # @param source_lines [Array<String>] lines of source file
            # @param definition_line [Integer] 0-indexed line of definition
            # @return [Array<Integer, Boolean>] blank count and whether doc block exists
            def analyze_spacing(source_lines, definition_line)
              blank_count = 0
              has_doc_block = false

              (definition_line - 1).downto(0) do |i|
                line = source_lines[i].to_s.rstrip
                stripped = line.strip

                if stripped.empty?
                  blank_count += 1
                elsif stripped.start_with?('#')
                  # Skip Ruby magic comments - they're not YARD documentation
                  next if magic_comment?(stripped)

                  has_doc_block = true
                  break
                else
                  # Non-comment, non-blank line - no documentation above
                  break
                end
              end

              [blank_count, has_doc_block]
            end

            # Check if a comment line is a Ruby magic comment
            # @param line [String] stripped comment line
            # @return [Boolean] true if line is a magic comment
            def magic_comment?(line)
              # Ruby magic comments: frozen_string_literal, encoding, warn_indent, shareable_constant_value
              line.match?(/^#\s*(frozen[_-]string[_-]literal|encoding|warn[_-]indent|shareable[_-]constant[_-]value)\s*:/i)
            end

            # Check if the given pattern is enabled in configuration
            # @param violation_type [String] 'single' or 'orphaned'
            # @return [Boolean] whether the pattern is enabled
            def pattern_enabled?(violation_type)
              patterns = config_or_default('EnabledPatterns')
              case violation_type
              when 'single'
                patterns['SingleBlankLine']
              when 'orphaned'
                patterns['OrphanedDocs']
              else
                true
              end
            end
          end
        end
      end
    end
  end
end
