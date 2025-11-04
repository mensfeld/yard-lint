# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module Stats
          # Runs yard stats to check the docs and reuse warnings and errors
          class Validator < Base
            private

          # Runs yard stats with proper settings on a given dir and files
          # @param dir [String] dir where we should generate the temp docs
          # @param escaped_file_names [String] files for which we want to get the stats
          # @return [Hash] shell command execution hash results
            def yard_cmd(dir, escaped_file_names)
              cmd = <<~CMD
            yard stats \
              #{shell_arguments} \
            --compact \
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