# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagTypePosition
          # Validates type annotation position in @param and @option tags
          # YARD standard (type_after_name): @param name [String] description
          # Alternative (type_first): @param name [String] description
          #
          # Note: @return tags are not checked as they don't have parameter names
          class Validator < Base
            # Enable in-process execution
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Checks type annotation position in @param and @option tags.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.file && File.exist?(object.file)

              checked_tags = config_or_default('CheckedTags')
              style = enforced_style

              source_lines = File.readlines(object.file)
              start_line = [object.line - 50, 0].max
              end_line = [object.line, source_lines.length - 1].min

              # Look for comments before the object definition
              (start_line...(end_line - 1)).reverse_each do |line_num|
                line = source_lines[line_num].to_s.strip

                # Skip empty lines
                next if line.empty?

                # Stop if we hit code (non-comment line)
                break unless line.start_with?('#')

                # Skip comment-only lines without tags
                next unless line.include?('@')

                checked_tags.each do |tag_name|
                  if style == 'type_first'
                    # Detect: @tag_name word [Type] (violation when type_first is enforced)
                    pattern = /@#{tag_name}\s+(\w+)\s+\[([^\]]+)\]/
                    if line =~ pattern
                      param_name = ::Regexp.last_match(1)
                      type_info = ::Regexp.last_match(2)
                      collector.puts "#{object.file}:#{line_num + 1}: #{object.title}"
                      collector.puts "#{tag_name}|#{param_name}|#{type_info}|type_after_name"
                    end
                  else
                    # Detect: @tag_name [Type] word (violation when type_after_name is enforced)
                    pattern = /@#{tag_name}\s+\[([^\]]+)\]\s+(\w+)/
                    if line =~ pattern
                      type_info = ::Regexp.last_match(1)
                      param_name = ::Regexp.last_match(2)
                      collector.puts "#{object.file}:#{line_num + 1}: #{object.title}"
                      collector.puts "#{tag_name}|#{param_name}|#{type_info}|type_first"
                    end
                  end
                end
              end
            end

            private

            # Runs YARD query to check type position in tags
            # @param dir [String] directory where YARD database is stored
            # @param file_list_path [String] path to temp file containing file paths (one per line)
            # @return [Hash] shell command execution results
            def yard_cmd(dir, file_list_path)
              # Write query to a temporary file to avoid shell escaping issues
              cmd = "cat #{Shellwords.escape(file_list_path)} | xargs yard list --query #{query} "

              Tempfile.create(['yard_query', '.sh']) do |f|
                f.write("#!/bin/sh\n")
                f.write(cmd)
                f.write("#{shell_arguments} -b #{Shellwords.escape(dir)}\n")
                f.flush
                f.chmod(0o755)

                shell("sh #{Shellwords.escape(f.path)}")
              end
            end

            # YARD query that checks source code directly instead of docstring.all
            # Detects patterns based on configured style
            # @return [String] YARD query string
            def query
              <<~QUERY.strip
                '
                require "ripper"

                checked_tags = #{checked_tags_array}
                enforced_style = "#{enforced_style}"

                # Read the source file and find comment lines for this object
                return false unless object.file && File.exist?(object.file)

                source_lines = File.readlines(object.file)
                start_line = [object.line - 50, 0].max
                end_line = [object.line, source_lines.length - 1].min

                # Look for comments before the object definition
                # Start just before the object line and scan backward
                (start_line...(end_line - 1)).reverse_each do |line_num|
                  line = source_lines[line_num].to_s.strip

                  # Skip empty lines
                  next if line.empty?

                  # Stop if we hit code (non-comment line)
                  break unless line.start_with?("#")

                  # Skip comment-only lines without tags
                  next unless line.include?("@")

                  checked_tags.each do |tag_name|
                    if enforced_style == "type_first"
                      # Detect: @tag_name word [Type] (violation when type_first is enforced)
                      pattern = /@\#{tag_name}\\s+(\\w+)\\s+\\[([^\\]]+)\\]/
                      if line =~ pattern
                        param_name = $1
                        type_info = $2
                        puts object.file + ":" + (line_num + 1).to_s + ": " + object.title
                        puts tag_name + "|" + param_name + "|" + type_info + "|type_after_name"
                      end
                    else
                      # Detect: @tag_name [Type] word (violation when type_after_name is enforced)
                      pattern = /@\#{tag_name}\\s+\\[([^\\]]+)\\]\\s+(\\w+)/
                      if line =~ pattern
                        type_info = $1
                        param_name = $2
                        puts object.file + ":" + (line_num + 1).to_s + ": " + object.title
                        puts tag_name + "|" + param_name + "|" + type_info + "|type_first"
                      end
                    end
                  end
                end

                false
                '
              QUERY
            end

            # @return [String] the enforced style ('type_after_name' (standard) or 'type_first')
            def enforced_style
              config_or_default('EnforcedStyle')
            end

            # Array of tag names to check, formatted for YARD query
            # @return [String] Ruby array literal string
            def checked_tags_array
              tags = config_or_default('CheckedTags')
              "[#{tags.map { |t| "\"#{t}\"" }.join(',')}]"
            end
          end
        end
      end
    end
  end
end
