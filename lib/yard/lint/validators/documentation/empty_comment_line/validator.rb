# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module EmptyCommentLine
          # Validates empty comment lines at the start/end of documentation blocks
          class Validator < Validators::Base
            private

            # Runs YARD query to check for empty comment lines
            # @param dir [String] directory where YARD database is stored
            # @param file_list_path [String] path to temp file containing file paths
            # @return [Hash] shell command execution results
            def yard_cmd(dir, file_list_path)
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

            # YARD query that reads source files and detects empty leading/trailing lines
            # Uses semicolons and conditionals to avoid unsupported `next` statements
            # @return [String] YARD query string
            def query
              # Use single-quoted heredoc to avoid escaping issues with backslashes
              <<~'QUERY'.strip.sub('CHECK_LEADING', check_leading?.to_s).sub('CHECK_TRAILING', check_trailing?.to_s)
                'check_leading = CHECK_LEADING; check_trailing = CHECK_TRAILING; if object.file && File.exist?(object.file) && object.line > 1; source_lines = File.readlines(object.file); definition_line = object.line - 1; comment_end = nil; comment_start = nil; (definition_line - 1).downto(0) do |i|; line = source_lines[i].to_s.rstrip; stripped = line.strip; if stripped.empty? && comment_end.nil?; ; elsif stripped.start_with?("#"); comment_end ||= i; comment_start = i; else; break; end; end; if comment_start && comment_end; comment_block = source_lines[comment_start..comment_end]; first_content_idx = nil; last_content_idx = nil; comment_block.each_with_index do |line, idx|; stripped = line.strip; has_content = stripped.match?(/^#.+\S/); if has_content; first_content_idx ||= idx; last_content_idx = idx; end; end; if first_content_idx && last_content_idx; violations = []; if check_leading; (0...first_content_idx).each do |i|; if comment_block[i].strip.match?(/^#\s*$/); violations << "leading:" + (comment_start + i + 1).to_s; end; end; end; if check_trailing; ((last_content_idx + 1)...comment_block.length).each do |i|; if comment_block[i].strip.match?(/^#\s*$/); violations << "trailing:" + (comment_start + i + 1).to_s; end; end; end; unless violations.empty?; puts object.file + ":" + object.line.to_s + ": " + object.title; puts violations.join("|"); end; end; end; end; false'
              QUERY
            end

            # @return [Boolean] whether to check for leading empty lines
            def check_leading?
              patterns = config_or_default('EnabledPatterns')
              patterns['Leading']
            end

            # @return [Boolean] whether to check for trailing empty lines
            def check_trailing?
              patterns = config_or_default('EnabledPatterns')
              patterns['Trailing']
            end
          end
        end
      end
    end
  end
end
