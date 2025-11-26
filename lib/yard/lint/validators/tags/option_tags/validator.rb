# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module OptionTags
          # Validator to check methods with options hash have @option tags
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks if methods with options parameter have @option tags.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.is_a?(YARD::CodeObjects::MethodObject)

              parameter_names = config_parameter_names

              # Check if method has a parameter named "options" or "opts" etc.
              has_options_param = object.parameters.any? do |param|
                param_name = param[0].to_s.gsub(/[*:]/, '')
                parameter_names.include?(param_name)
              end

              return unless has_options_param

              # Check if method has any @option tags
              option_tags = object.tags(:option)

              return unless option_tags.empty?

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts 'missing_option_tags'
            end

            private

            # Runs yard list query to find methods with options parameter but missing @option tags
            # @param dir [String] dir where the yard db is (or where it should be generated)
            # @param file_list_path [String] path to temp file containing file paths (one per line)
            # @return [Hash] shell command execution hash results
            def yard_cmd(dir, file_list_path)
              cmd = <<~CMD
                cat #{Shellwords.escape(file_list_path)} | xargs yard list \
                --private \
                --protected \
                -b #{Shellwords.escape(dir)}
              CMD
              cmd = cmd.tr("\n", ' ')
              cmd = cmd.gsub('yard list', "yard list --query #{query}")

              shell(cmd)
            end

            # @return [String] yard query to find methods with options parameter
            #   but no @option tags
            def query
              parameter_names = config_parameter_names
              <<~QUERY
                '
                  if object.is_a?(YARD::CodeObjects::MethodObject)
                      # Check if method has a parameter named "options" or "opts"
                    has_options_param = object.parameters.any? do |param|
                      param_name = param[0].to_s.gsub(/[*:]/, '')
                      #{parameter_names.inspect}.include?(param_name)
                      end

                    if has_options_param
                        # Check if method has any @option tags
                      option_tags = object.tags(:option)

                      if option_tags.empty?
                        puts object.file + ':' + object.line.to_s + ': ' + object.title
                        puts 'missing_option_tags'
                        end
                      end
                    end
                  false
                '
              QUERY
            end

            # @return [Array<String>] parameter names that should have @option tags
            def config_parameter_names
              config.validator_config('Tags/OptionTags', 'ParameterNames') || Config.defaults['ParameterNames']
            end
          end
        end
      end
    end
  end
end
