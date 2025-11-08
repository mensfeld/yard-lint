# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedObjects
          # Runs yard list to check for undocumented objects
          class Validator < Base
            # Base query to find all objects without documentation
            # Uses docstring.all.empty? to check for truly undocumented objects
            # docstring.all includes both text and explicit tags (e.g., @return, @param)
            # This correctly excludes objects with explicit tags but no descriptive text
            BASE_QUERY = 'docstring.all.empty?'

            # Additional filter to exclude empty initialize methods (no parameters)
            # when AllowEmptyInitialize config option is enabled
            INITIALIZE_FILTER = '!(type == :method && name == :initialize && parameters.empty?)'

            private_constant :BASE_QUERY, :INITIALIZE_FILTER

            private

            # Builds the YARD query based on configuration
            # @return [String] the complete YARD query with filters
            def build_query
              query_parts = [BASE_QUERY]

              # Add initialize filter if AllowEmptyInitialize is enabled
              if config.validator_config('Documentation/UndocumentedObjects',
                'AllowEmptyInitialize')
                query_parts << INITIALIZE_FILTER
              end

              "'#{query_parts.join(' && ')}'"
            end

            # Runs yard list query with proper settings on a given dir and files
            # @param dir [String] dir where we should generate the temp docs
            # @param escaped_file_names [String] files for which we want to get the stats
            # @return [Hash] shell command execution hash results
            def yard_cmd(dir, escaped_file_names)
              cmd = <<~CMD
                yard list \
                  #{shell_arguments} \
                  --query #{build_query} \
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
