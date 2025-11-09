# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module UnknownParameterName
          # Runs YARD stats command to check for unknownparametername
          class Validator < Base
            private

            # Runs YARD stats command with proper settings on a given dir and files
            # @param dir [String] dir where we should generate the temp docs
            # @param file_list_path [String] path to temp file containing file paths (one per line)
            # @return [Hash] shell command execution hash results
            def yard_cmd(dir, file_list_path)
              cmd = <<~CMD
                cat #{Shellwords.escape(file_list_path)} | xargs yard stats \
                  #{shell_arguments} \
                --compact \
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
