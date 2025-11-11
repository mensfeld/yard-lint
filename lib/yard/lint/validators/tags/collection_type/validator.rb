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
              cmd = "cat #{Shellwords.escape(file_list_path)} | xargs yard list --query #{query} "

              Tempfile.create(['yard_query', '.sh']) do |f|
                f.write("#!/bin/bash\n")
                f.write(cmd)
                f.write("#{shell_arguments} -b #{Shellwords.escape(dir)}\n")
                f.flush
                f.chmod(0o755)

                shell("bash #{Shellwords.escape(f.path)}")
              end
            end

            # YARD query that finds incorrect collection syntax based on EnforcedStyle
            # Format output as two lines per violation:
            #   Line 1: file.rb:LINE: ClassName#method_name
            #   Line 2: tag_name|type_string|detected_style
            # @return [String] YARD query string
            def query
              style = enforced_style

              <<~QUERY.strip
                '
                docstring
                  .tags
                  .select { |tag| #{validated_tags_array}.include?(tag.tag_name) }
                  .each do |tag|
                    next unless tag.types

                    tag.types.each do |type_str|
                      detected_style = nil

                      # Check for Hash<...> syntax (angle brackets)
                      if type_str =~ /Hash<.*>/
                        detected_style = "short"
                      # Check for Hash{...} syntax (curly braces)
                      elsif type_str =~ /Hash\\{.*\\}/
                        detected_style = "long"
                      # Check for {...} syntax without Hash prefix
                      elsif type_str =~ /^\\{.*\\}$/
                        detected_style = "short"
                      end

                      # Report violations based on enforced style
                      if detected_style && detected_style != "#{style}"
                        puts object.file + ":" + object.line.to_s + ": " + object.title
                        puts tag.tag_name + "|" + type_str + "|" + detected_style
                        break
                      end
                    end
                  end

                false
                '
              QUERY
            end

            # Gets the enforced collection style from configuration
            # @return [String] 'long' or 'short'
            def enforced_style
              config_or_default('EnforcedStyle')
            end

            # Array of tag names to validate, formatted for YARD query
            # @return [String] Ruby array literal string
            def validated_tags_array
              tags = config_or_default('ValidatedTags')
              "[#{tags.map { |t| "\"#{t}\"" }.join(',')}]"
            end
          end
        end
      end
    end
  end
end
