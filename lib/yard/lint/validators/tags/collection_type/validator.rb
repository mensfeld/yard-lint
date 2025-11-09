# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module CollectionType
          # Validates Hash collection type syntax in YARD tags
          class Validator < Base
            private

            # Runs YARD query to find incorrect Hash<K, V> syntax
            # @param dir [String] directory where YARD database is stored
            # @param file_list_path [String] path to temp file containing file paths (one per line)
            # @return [Hash] shell command execution results
            def yard_cmd(dir, file_list_path)
              # Write query to a temporary file to avoid shell escaping issues
              require 'tempfile'

              Tempfile.create(['yard_query', '.sh']) do |f|
                f.write("#!/bin/bash\n")
                f.write("cat #{Shellwords.escape(file_list_path)} | xargs yard list --query #{query} ")
                f.write("#{shell_arguments} -b #{Shellwords.escape(dir)}\n")
                f.flush
                f.chmod(0o755)

                shell("bash #{Shellwords.escape(f.path)}")
              end
            end

            # YARD query that finds Hash<K, V> syntax in type annotations
            # Format output as two lines per violation:
            #   Line 1: file.rb:LINE: ClassName#method_name
            #   Line 2: tag_name|type_string
            # @return [String] YARD query string
            def query
              <<~QUERY.strip
                '
                docstring
                  .tags
                  .select { |tag| #{validated_tags_array}.include?(tag.tag_name) }
                  .each do |tag|
                    next unless tag.types

                    tag.types.each do |type_str|
                      # Check for Hash<...> syntax (should be Hash{...})
                      if type_str =~ /Hash<.*>/
                        puts object.file + ":" + object.line.to_s + ": " + object.title
                        puts tag.tag_name + "|" + type_str
                        break
                      end
                    end
                  end

                false
                '
              QUERY
            end

            # Array of tag names to validate, formatted for YARD query
            # @return [String] Ruby array literal string
            def validated_tags_array
              tags = config.validator_config('Tags/CollectionType', 'ValidatedTags') || %w[
                param option return yieldreturn
              ]
              "[#{tags.map { |t| "\"#{t}\"" }.join(',')}]"
            end
          end
        end
      end
    end
  end
end
