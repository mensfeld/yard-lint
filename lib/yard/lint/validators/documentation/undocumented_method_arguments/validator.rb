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

              missing = missing_param_names(object, params)
              return unless missing

              names = missing.map! { |name| escape_field(display_name(name)) }.join(',')
              collector.puts "#{object.file}:#{object.line}: #{object.title}\t#{names}"
            end

            private

            # Find the parameters of a method that have no @param tag.
            # @param object [YARD::CodeObjects::MethodObject] the method to check
            # @param params [Array<Array>] non-splat/block parameters
            # @return [Array<String>, nil] names of the undocumented parameters
            #   (empty in count-only mode, which does not know them), or nil when
            #   documentation is complete
            def missing_param_names(object, params)
              # Tags nested inside @overload blocks live on the overload's own
              # docstring, so all_typed_tags collects those @param tags too.
              param_tags = all_typed_tags(object.docstring, %w[param])

              if config_or_default('CheckParameterNames')
                documented = param_tags.map { |tag| normalize_param_name(tag.name) }
                missing = params.map { |param| normalize_param_name(param[0]) }.uniq - documented
                missing unless missing.empty?
              elsif params.size > param_tags.size
                []
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

            # YARD names a destructured parameter `(a, b)` as `a, b`, keeping the
            # source whitespace, and drops only the outermost pair, so a nested one
            # can come back unbalanced (`((a, b), c)` as `a, b), c`). Rebalance,
            # put the outer pair back and collapse whitespace so the message
            # shows it as one parameter.
            # @param name [String] normalized parameter name
            # @return [String] name as shown in the message
            def display_name(name)
              return name unless name.include?(',')

              depth = 0
              unopened = 0
              name.each_char do |char|
                if char == '('
                  depth += 1
                elsif char == ')'
                  depth.zero? ? unopened += 1 : depth -= 1
                end
              end

              "(#{'(' * unopened}#{name.gsub(/\s+/, ' ')}#{')' * depth})"
            end

            # Escapes ',' (the name separator), tabs and newlines (the line and
            # field separators) and '%' (the escape character)
            # @param text [String] raw field text
            # @return [String] escaped field text
            def escape_field(text)
              return text unless text.match?(/[%,\t\n]/)

              text.gsub(/[%,\t\n]/, '%' => '%25', ',' => '%2C', "\t" => '%09', "\n" => '%0A')
            end
          end
        end
      end
    end
  end
end
