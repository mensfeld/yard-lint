# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedMethodArguments
          # Runs yard list to check for missing args docs on methods that were documented
          class Validator < Base
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

          private

          # Runs yard list query with proper settings on a given dir and files
          # @param dir [String] dir where we should generate the temp docs
          # @param escaped_file_names [String] files for which we want to get the stats
          # @return [Hash] shell command execution hash results
            def yard_cmd(dir, escaped_file_names)
              shell_args = shell_arguments
              UNWANTED_OPTIONS.each { |opt| shell_args.gsub!(opt, '') }

              cmd = <<~CMD
            yard list \
              #{shell_args} \
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