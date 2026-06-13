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
