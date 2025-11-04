# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module OptionTags
          # Validator to check methods with options hash have @option tags
          class Validator < Base
            private

          # Runs yard list query to find methods with options parameter but missing @option tags
          # @param dir [String] dir where the yard db is (or where it should be generated)
          # @param escaped_file_names [String] files for which we want to get the stats
          # @return [Hash] shell command execution hash results
            def yard_cmd(dir, escaped_file_names)
              cmd = <<~CMD
            yard list \
            --private \
            --protected \
            -b #{Shellwords.escape(dir)} \
              #{escaped_file_names}
          CMD
              cmd = cmd.tr("\n", ' ')
              cmd = cmd.gsub('yard list', "yard list --query #{query}")

              shell(cmd)
            end

          # @return [String] yard query to find methods with options parameter but no @option tags
            def query
              <<~QUERY
            '
              if object.is_a?(YARD::CodeObjects::MethodObject)
                  # Check if method has a parameter named "options" or "opts"
                has_options_param = object.parameters.any? do |param|
                  param_name = param[0].to_s.gsub(/[*:]/, '')
                  ['options', 'opts', 'kwargs'].include?(param_name)
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
        end
        end
      end
    end
  end
end