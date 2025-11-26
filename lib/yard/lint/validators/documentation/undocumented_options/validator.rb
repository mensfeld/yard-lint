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
          end
        end
      end
    end
  end
end
