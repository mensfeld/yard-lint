# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedObjects
          # Runs yard list to check for undocumented objects
          class Validator < Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Checks for empty docstrings and outputs location with arity for methods.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              # Check if docstring is empty
              return unless object.docstring.all.empty?

              if object.is_a?(YARD::CodeObjects::MethodObject)
                # For methods, include arity (excluding splat and block params)
                arity = object.parameters.reject { |p| p[0].to_s.start_with?('*', '&') }.size
                collector.puts "#{object.file}:#{object.line}: #{object.title}|#{arity}"
              else
                collector.puts "#{object.file}:#{object.line}: #{object.title}"
              end
            end

            private

            # Runs yard list query with proper settings on a given dir and files
            # @param dir [String] dir where we should generate the temp docs
            # @param file_list_path [String] path to temp file containing file paths (one per line)
            # @return [Hash] shell command execution hash results
            def yard_cmd(dir, file_list_path)
              cmd = <<~CMD
                cat #{Shellwords.escape(file_list_path)} | xargs yard list \
                  #{shell_arguments} \
                  --query #{query} \
                  -q \
                  -b #{Shellwords.escape(dir)}
              CMD
              cmd = cmd.tr("\n", ' ')

              shell(cmd)
            end

            # Custom query that outputs parameter count for methods
            # Format: file.rb:LINE: ElementName|ARITY
            # Arity counts all parameters (required + optional) excluding splat and block
            # @return [String] YARD query string
            def query
              <<~QUERY.chomp
                "if docstring.all.empty? then if object.is_a?(YARD::CodeObjects::MethodObject) then arity = object.parameters.reject { |p| p[0].start_with?('*', '&') }.size; puts object.file + ':' + object.line.to_s + ': ' + object.title + '|' + arity.to_s; else puts object.file + ':' + object.line.to_s + ': ' + object.title; end; false; end"
              QUERY
            end
          end
        end
      end
    end
  end
end
