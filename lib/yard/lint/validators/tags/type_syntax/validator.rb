# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TypeSyntax
          # Runs YARD to validate type syntax using TypesExplainer::Parser
          class Validator < Base
            # Enable in-process execution
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Validates type syntax in tags using YARD's TypesExplainer::Parser.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              validated_tags = config.validator_config('Tags/TypeSyntax', 'ValidatedTags') ||
                               %w[param option return yieldreturn]

              object.docstring.tags
                    .select { |tag| validated_tags.include?(tag.tag_name) }
                    .each do |tag|
                next unless tag.types

                tag.types.each do |type_str|
                  begin
                    YARD::Tags::TypesExplainer::Parser.parse(type_str)
                  rescue SyntaxError => e
                    collector.puts "#{object.file}:#{object.line}: #{object.title}"
                    collector.puts "#{tag.tag_name}|#{type_str}|#{e.message}"
                    break
                  end
                end
              end
            end

            private

            # Runs YARD query to validate type syntax on given files
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

            # YARD query that validates type syntax for each tag
            # Format output as two lines per violation:
            #   Line 1: file.rb:LINE: ClassName#method_name
            #   Line 2: tag_name|type_string|error_message
            # @return [String] YARD query string
            def query
              <<~QUERY.strip
                '
                require "yard"

                docstring
                  .tags
                  .select { |tag| #{validated_tags_array}.include?(tag.tag_name) }
                  .each do |tag|
                    next unless tag.types

                    tag.types.each do |type_str|
                      begin
                        YARD::Tags::TypesExplainer::Parser.parse(type_str)
                      rescue SyntaxError => e
                        puts object.file + ":" + object.line.to_s + ": " + object.title
                        puts tag.tag_name + "|" + type_str + "|" + e.message
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
              tags = config.validator_config('Tags/TypeSyntax', 'ValidatedTags') || %w[
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
