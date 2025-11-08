# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedObjects
          # Runs yard list to check for undocumented objects
          class Validator < Base
            private

            # Runs yard list query with proper settings on a given dir and files
            # @param dir [String] dir where we should generate the temp docs
            # @param escaped_file_names [String] files for which we want to get the stats
            # @return [Hash] shell command execution hash results
            def yard_cmd(dir, escaped_file_names)
              cmd = <<~CMD
                yard list \
                  #{shell_arguments} \
                  --query #{query} \
                  -q \
                  -b #{Shellwords.escape(dir)} \
                  #{escaped_file_names}
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
