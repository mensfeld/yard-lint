# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedMethodArguments
          # Runs yard list to check for missing args docs on methods that were documented
          class Validator < Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Options that stats supports but not list
            UNWANTED_OPTIONS = %w[
              --list-undoc
            ].freeze

            # Query to find all the documented methods that have some undocumented
            # arguments
            QUERY = <<~QUERY.tr("\n", ' ')
              '
                type == :method &&
                !is_alias? &&
                is_explicit? &&
                (parameters.size > @@param.size)
              '
            QUERY

            private_constant :UNWANTED_OPTIONS, :QUERY

            # Execute query for a single object during in-process execution.
            # Finds methods where parameters.size > @param tags count.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              # Only check methods
              return unless object.type == :method
              # Skip aliases and implicit methods
              return if object.is_alias?
              return unless object.is_explicit?

              # Check if parameters count exceeds @param tags count
              param_count = object.parameters.size
              param_tags_count = object.tags(:param).size

              return unless param_count > param_tags_count

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
            end

            private

            # Runs yard list query with proper settings on a given dir and files
            # @param dir [String] dir where we should generate the temp docs
            # @param file_list_path [String] path to temp file containing file paths (one per line)
            # @return [Hash] shell command execution hash results
            def yard_cmd(dir, file_list_path)
              shell_args = shell_arguments
              UNWANTED_OPTIONS.each { |opt| shell_args.gsub!(opt, '') }

              cmd = <<~CMD
                cat #{Shellwords.escape(file_list_path)} | xargs yard list \
                  #{shell_args} \
                --query #{QUERY} \
                -q \
                -b #{Shellwords.escape(dir)}
              CMD
              cmd = cmd.tr("\n", ' ')

              shell(cmd)
            end
          end
        end
      end
    end
  end
end
