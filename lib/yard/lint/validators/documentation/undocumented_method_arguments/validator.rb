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

              # Splat (*args, **opts) and block (&block) parameters are excluded -
              # blocks are documented with @yield rather than @param, matching the
              # arity convention used everywhere else in the gem (e.g. method_allowed?).
              params = object.parameters.reject { |p| p[0].to_s.start_with?('*', '&') }
              return if params.empty?

              # Opt-in: defer fully-undocumented methods to
              # Documentation/UndocumentedObjects instead of reporting them here too.
              return if config_or_default('SkipFullyUndocumented') && object.docstring.blank?

              return unless arguments_missing_docs?(object, params)

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
            end

            private

            # Decide whether a method's parameters are under-documented.
            # @param object [YARD::CodeObjects::MethodObject] the method to check
            # @param params [Array<Array>] non-splat/block parameters
            # @return [Boolean] true if documentation is missing
            def arguments_missing_docs?(object, params)
              # Tags nested inside @overload blocks live on the overload's own
              # docstring, so all_typed_tags collects those @param tags too.
              param_tags = all_typed_tags(object.docstring, %w[param])

              if config_or_default('CheckParameterNames')
                documented = param_tags.map { |tag| normalize_param_name(tag.name) }
                params.any? { |param| !documented.include?(normalize_param_name(param[0])) }
              else
                params.size > param_tags.size
              end
            end

            # Normalize a parameter or @param name for comparison by stripping a
            # trailing `:` - keyword parameters appear as `name:` in
            # object.parameters but `name` in @param tag names.
            # @param name [String, Symbol, nil] the raw name
            # @return [String] the normalized name
            def normalize_param_name(name)
              name.to_s.sub(/:\z/, '')
            end
          end
        end
      end
    end
  end
end
