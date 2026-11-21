# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedObjects
          # Runs yard list to check for undocumented objects
          class Validator < Base
            # Enable in-process execution for this validator
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Checks for empty docstrings and outputs location with arity for methods.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return if parent_class_allowed?(object)

              if object.is_a?(YARD::CodeObjects::MethodObject)
                # A module_function pair is reported once, on its public class method
                twin = module_function_twin(object)
                return if twin && object.scope == :instance

                # YARD gives one half of an undocumented `?` pair an inferred `@return`
                return unless object.docstring.all.empty? || twin&.docstring&.all&.empty?

                # For methods, include arity (excluding splat and block params)
                arity = object.parameters.reject { |p| p[0].to_s.start_with?('*', '&') }.size
                collector.puts "#{object.file}:#{object.line}: #{object.title}|#{arity}"
              else
                return unless object.docstring.all.empty?

                collector.puts "#{object.file}:#{object.line}: #{object.title}"
              end
            end
          end
        end
      end
    end
  end
end
