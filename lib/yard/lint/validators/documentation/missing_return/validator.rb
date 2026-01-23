# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module MissingReturn
          # Runs a query that will pick all methods that do not have a @return tag documented
          class Validator < Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Finds methods without @return tag.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              # Only check methods
              return unless object.type == :method
              # Skip aliases and implicit methods
              return if object.is_alias?
              return unless object.is_explicit?

              # Check if @return tag is missing
              return_tag = object.tag(:return)
              return unless return_tag.nil?

              # Calculate arity (exclude splat and block parameters)
              arity = object.parameters.reject { |p| p[0].to_s.start_with?('*', '&') }.size

              # Output method with arity for parser filtering
              collector.puts "#{object.file}:#{object.line}: #{object.title}|#{arity}"
            end
          end
        end
      end
    end
  end
end
