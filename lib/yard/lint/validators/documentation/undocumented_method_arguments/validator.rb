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
              return if parent_class_allowed?(object)
              return if method_allowed?(object)
              # Skip attribute methods (@!attribute directive) - their setter parameter
              # doesn't need explicit @param documentation, matching attr_accessor behavior
              return if object.is_attribute?

              # Check if parameters count exceeds @param tags count; tags nested
              # inside @overload blocks live on the overload's own docstring,
              # so count those too. Splat (*args, **opts) and block (&block)
              # parameters are excluded from the count - blocks are documented
              # with @yield rather than @param, and this matches the arity
              # convention used everywhere else in the gem (e.g. method_allowed?).
              param_count = object.parameters.reject { |p| p[0].to_s.start_with?('*', '&') }.size
              param_tags_count = all_typed_tags(object.docstring, %w[param]).size

              return unless param_count > param_tags_count

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
            end
          end
        end
      end
    end
  end
end
