# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ApiTags
          # Validator to check for @api tag presence and validity
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks for @api tag presence and validity.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              allowed_list = allowed_apis

              if object.has_tag?(:api)
                api_value = object.tag(:api).text
                unless allowed_list.include?(api_value)
                  collector.puts "#{object.file}:#{object.line}: #{object.title}"
                  collector.puts "invalid:#{api_value}"
                end
              elsif require_api_tags?
                # Only check public methods/classes if require_api_tags is enabled
                visibility = object.visibility.to_s
                if visibility == 'public' && !object.root?
                  collector.puts "#{object.file}:#{object.line}: #{object.title}"
                  collector.puts 'missing'
                end
              end
            end

            private

            # Runs yard list query to find objects missing or with invalid @api tags
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

            # @return [String] yard query to find objects with missing or invalid @api tags
            def query
              allowed_list = allowed_apis.map { |api| "'#{api}'" }.join(', ')

              <<~QUERY
                '
                  if object.has_tag?(:api)
                    api_value = object.tag(:api).text
                    unless [#{allowed_list}].include?(api_value)
                      puts object.file + ':' + object.line.to_s + ': ' + object.title
                      puts 'invalid:' + api_value
                      end
                  elsif #{require_api_tags?}
                      # Only check public methods/classes if require_api_tags is enabled
                    visibility = object.visibility.to_s
                    if visibility == 'public' && !object.root?
                      puts object.file + ':' + object.line.to_s + ': ' + object.title
                      puts 'missing'
                      end
                    end
                  false
                '
              QUERY
            end

            # @return [Array<String>] list of allowed API values
            def allowed_apis
              config.validator_config('Tags/ApiTags', 'AllowedApis') || %w[public private internal]
            end

            # @return [Boolean] whether @api tags are required on public objects
            def require_api_tags?
              config.validator_enabled?('Tags/ApiTags')
            end
          end
        end
      end
    end
  end
end
