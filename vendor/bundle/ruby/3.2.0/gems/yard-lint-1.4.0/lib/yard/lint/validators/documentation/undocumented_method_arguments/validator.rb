# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedMethodArguments
          # Runs yard list to check for missing args docs on methods that were documented
          class Validator < Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Finds methods where parameters.size > @param tags count.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              # Only check methods
              return unless object.type == :method
              # Skip aliases and implicit methods
              return if object.is_alias?
              return unless object.is_explicit?

              # Check if parameters count exceeds @param tags count
              param_count = object.parameters.size
              param_tags_count = object.tags(:param).size

              return unless param_count > param_tags_count

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
            end
          end
        end
      end
    end
  end
end
