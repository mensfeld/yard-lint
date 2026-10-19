# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedBooleanMethods
          # Runs a query that will pick all the boolean methods (ending with ?) that
          # do not have a return documented
          class Validator < Base
            # A `@return` written by the user (top level or inside `@overload`), or a
            # macro that may carry one
            USER_RETURN_REGEX = /^\s*@(?:return|!?macro)\b/
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Finds boolean methods (ending with ?) without a user-written @return tag.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              # Only check methods
              return unless object.type == :method
              # Skip aliases and implicit methods
              return if object.is_alias?
              return unless object.is_explicit?
              return if parent_class_allowed?(object)
              # Only check boolean methods (ending with ?)
              return unless object.name.to_s.end_with?('?')

              # Undocumented methods are reported by UndocumentedObjects
              return if object.docstring.all.empty?
              # YARD adds `@return [Boolean]` to every `?` method without one, so the
              # tags cannot tell; read the raw docstring instead
              return if object.docstring.all.match?(USER_RETURN_REGEX)

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
            end
          end
        end
      end
    end
  end
end
