# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedBooleanMethods
          # Runs a query that will pick all the boolean methods (ending with ?) that
          # do not have a return type or return description documented
          class Validator < Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Query to find all the boolean methods without proper return documentation
            # Requires either: no @return tag, OR @return tag with no types specified
            # Accepts @return [Boolean] without description text as valid documentation
            QUERY = <<~QUERY.tr("\n", ' ')
              '
                type == :method &&
                !is_alias? &&
                is_explicit? &&
                name.to_s.end_with?("?") &&
                (tag("return").nil? || tag("return").types.to_a.empty?)
              '
            QUERY

            private_constant :QUERY

            # Execute query for a single object during in-process execution.
            # Finds boolean methods (ending with ?) without @return tag or return types.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              # Only check methods
              return unless object.type == :method
              # Skip aliases and implicit methods
              return if object.is_alias?
              return unless object.is_explicit?
              # Only check boolean methods (ending with ?)
              return unless object.name.to_s.end_with?('?')

              # Check if @return tag is missing or has no types
              return_tag = object.tag(:return)
              return unless return_tag.nil? || return_tag.types.to_a.empty?

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
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
