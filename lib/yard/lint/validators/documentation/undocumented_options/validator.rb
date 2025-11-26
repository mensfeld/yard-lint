# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedOptions
          # Validates that methods with options hash parameters have @option tags
          class Validator < Validators::Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Finds methods with options parameters but no @option tags.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              # Only check method objects
              return unless object.is_a?(YARD::CodeObjects::MethodObject)

              params = object.parameters || []

              # Check for options-style parameters
              has_options_param = params.any? do |p|
                param_name = p[0].to_s
                # Match options, option, opts, opt, kwargs or double-splat (**)
                param_name.match?(/^(options?|opts?|kwargs)$/) ||
                  param_name.start_with?('**')
              end

              return unless has_options_param

              # Check if @option tags are missing
              option_tags = object.tags(:option)
              return unless option_tags.empty?

              # Output method location and parameter info
              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts params.map { |p| p.join(' ') }.join(', ')
            end

            # YARD query to detect methods with options parameters but no @option tags
            # @return [String] YARD Ruby query code
            def query
              <<~QUERY.strip
                'if object.is_a?(YARD::CodeObjects::MethodObject); params = object.parameters || []; has_options_param = params.any? { |p| p[0] =~ /^(options?|opts?|kwargs)$/ || p[0] =~ /^\\*\\*/ || (p[0] =~ /^(options?|opts?|kwargs)$/ && p[1] =~ /^\\{\\}/) }; if has_options_param; option_tags = object.tags(:option); if option_tags.empty?; puts object.file + ":" + object.line.to_s + ": " + object.title; puts params.map { |p| p.join(" ") }.join(", "); end; end; end; false'
              QUERY
            end

            private

            # Builds and executes the YARD command to detect undocumented options
            # @param dir [String] the directory containing the .yardoc database
            # @param file_list_path [String] path to file containing list of files to analyze
            # @return [String] command output
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
          end
        end
      end
    end
  end
end
