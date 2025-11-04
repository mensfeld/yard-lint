# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedBooleanMethods
          # Runs a query that will pick all the boolean methods (ending with ?) that
        # do not have a return type or return description documented
          class Validator < Base
          # Query to find all the boolean methods without proper return documentation
            QUERY = <<~QUERY.tr("\n", ' ')
          '
            type == :method &&
            !is_alias? &&
            is_explicit? &&
            name.to_s.end_with?("?") &&
            (tag("return").nil? || tag("return").text.to_s.strip.empty?)
          '
          QUERY

            private_constant :QUERY

          private

          # Runs yard list query with proper settings on a given dir and files
          # @param dir [String] dir where we should generate the temp docs
          # @param escaped_file_names [String] files for which we want to get the stats
          # @return [Hash] shell command execution hash results
            def yard_cmd(dir, escaped_file_names)
              cmd = <<~CMD
            yard list \
              #{shell_arguments} \
            --query #{QUERY} \
            -q \
            -b #{Shellwords.escape(dir)} \
              #{escaped_file_names}
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