# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module MeaninglessTag
          # Validates that @param/@option tags only appear on methods
          class Validator < Base
            private

            # Runs YARD query to find @param/@option tags on non-methods
            # @param dir [String] directory where YARD database is stored
            # @param file_list_path [String] path to temp file containing file paths (one per line)
            # @return [Hash] shell command execution results
            def yard_cmd(dir, file_list_path)
              # Write query to a temporary file to avoid shell escaping issues
              cmd = "cat #{Shellwords.escape(file_list_path)} | xargs yard list --query #{query} "

              Tempfile.create(['yard_query', '.sh']) do |f|
                f.write("#!/bin/bash\n")
                f.write(cmd)
                f.write("--private --protected #{shell_arguments} -b #{Shellwords.escape(dir)}\n")
                f.flush
                f.chmod(0o755)

                shell("bash #{Shellwords.escape(f.path)}")
              end
            end

            # YARD query that finds method-only tags on non-method objects
            # Format output as two lines per violation:
            #   Line 1: file.rb:LINE: ClassName
            #   Line 2: object_type|tag_name
            # @return [String] YARD query string
            def query
              <<~QUERY.strip
                '
                object_type = object.type.to_s

                if #{invalid_object_types_array}.include?(object_type)
                  docstring.tags.each do |tag|
                    if #{checked_tags_array}.include?(tag.tag_name)
                      puts object.file + ":" + object.line.to_s + ": " + object.title
                      puts object_type + "|" + tag.tag_name
                      break
                    end
                  end
                end

                false
                '
              QUERY
            end

            # Array of tag names to check, formatted for YARD query
            # @return [String] Ruby array literal string
            def checked_tags_array
              "[#{checked_tags.map { |t| "\"#{t}\"" }.join(',')}]"
            end

            # Array of invalid object types, formatted for YARD query
            # @return [String] Ruby array literal string
            def invalid_object_types_array
              "[#{invalid_object_types.map { |t| "\"#{t}\"" }.join(',')}]"
            end

            # @return [Array<String>] tags that should only appear on methods
            def checked_tags
              config_or_default('CheckedTags')
            end

            # @return [Array<String>] object types that shouldn't have method-only tags
            def invalid_object_types
              config_or_default('InvalidObjectTypes')
            end
          end
        end
      end
    end
  end
end
