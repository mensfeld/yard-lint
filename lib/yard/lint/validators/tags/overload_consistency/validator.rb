# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module OverloadConsistency
          # Validates each @overload's tags against that overload's own signature
          class Validator < Base
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.type == :method
              return if object.is_alias?
              return if module_function_copy?(object)

              overloads = object.tags(:overload)
              return if overloads.empty?

              shared = object.docstring.tags(:param).map { |tag| tag.name.to_s }
              offenses = overloads.flat_map { |overload| param_offenses(overload, shared) }
              offenses.concat(return_offenses(object, overloads))

              offenses.each do |kind, param, overload|
                collector.puts "#{object.file}:#{object.line}: #{object.title}"
                collector.puts "#{kind}|#{param}|#{overload.signature}"
              end
            end

            private

            # @param overload [YARD::Tags::OverloadTag] overload to check
            # @param shared [Array<String>] @param names on the method docstring, common to all overloads
            # @return [Array<Array>] [kind, param name, overload] offenses
            def param_offenses(overload, shared)
              documented = overload.docstring.tags(:param).map { |tag| tag.name.to_s }
              return [] if documented.empty?

              names = overload.parameters.map { |param| param[0].to_s }
              plain = names.reject { |name| name.start_with?('*', '&', '...') }.map { |name| name.sub(/:\z/, '') }

              offenses = (plain - documented - shared).map { |name| ['undocumented_param', name, overload] }

              # `...`, `*`, `**` and `&` take arguments no @param can name
              return offenses if names.any? { |name| %w[... * ** &].include?(name) }

              known = names.map { |name| name.delete_prefix('**').delete_prefix('*').delete_prefix('&').sub(/:\z/, '') }
              (documented.uniq - known).map { |name| ['unknown_param', name, overload] } + offenses
            end

            # @param object [YARD::CodeObjects::MethodObject] the method
            # @param overloads [Array<YARD::Tags::OverloadTag>] its overloads
            # @return [Array<Array>] [kind, param name, overload] offenses
            def return_offenses(object, overloads)
              return [] if object.docstring.has_tag?(:return)

              missing = overloads.reject { |overload| overload.docstring.has_tag?(:return) }
              return [] if missing.size == overloads.size

              missing.map { |overload| ['missing_return', nil, overload] }
            end
          end
        end
      end
    end
  end
end
