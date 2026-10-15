# frozen_string_literal: true

require 'did_you_mean'

module Yard
  module Lint
    module Validators
      module Documentation
        module ReferenceTypo
          # Validates that references in documentation are not probable typos
          class Validator < Base
            # Same matching rules YARD uses for `{name}` / `{name title}` links
            LINK_PATTERN = /(?<![\\!])\{(?!\})(\S+?)(?:\s[^}]*)?\}/

            # Code spans, fenced and indented code blocks hold code, not links
            CODE_PATTERN = /```.*?```|`[^`\n]*`|^(?: {4}|\t)[^\n]*/m

            # `Foo::Bar#baz`, `Foo.baz` or a namespace-relative `#baz`
            METHOD_REFERENCE = /\A(?<namespace>(?:::)?[A-Z]\w*(?:::[A-Z]\w*)*)?(?<separator>[#.])(?<name>[A-Za-z_]\w*[?!=]?)\z/

            # `Foo`, `Foo::Bar` or `::Foo::BAR`
            CONSTANT_REFERENCE = /\A(?:::)?[A-Z]\w*(?:::[A-Z]\w*)*\z/

            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            def in_process_query(object, collector)
              return if object.type == :method && object.is_alias?
              return if module_function_copy?(object)
              return if duplicate_docstring?(object)

              references(object).uniq.each do |reference|
                suggestion = suggest(object, reference)
                next unless suggestion

                collector.puts "#{object.file}:#{object.line}: #{object.title}"
                collector.puts "#{reference}|#{suggestion}"
              end
            end

            private

            # @param object [YARD::CodeObjects::Base] documented object
            # @return [Array<String>] link targets and `@see` names in its docs
            def references(object)
              overloads = object.tags(:overload)
              tags = object.tags + overloads.flat_map { |overload| overload.docstring.tags }

              texts = [object.docstring.to_s] + overloads.map { |overload| overload.docstring.to_s }
              tags.each do |tag|
                texts << tag.text.to_s unless tag.tag_name == 'example'
              end

              links = texts.flat_map do |text|
                text.gsub(CODE_PATTERN, '').scan(LINK_PATTERN).map(&:first)
              end

              links + tags.select { |tag| tag.tag_name == 'see' }.map { |tag| tag.name.to_s }
            end

            # @param object [YARD::CodeObjects::Base] documented object
            # @param reference [String] referenced name
            # @return [String, nil] corrected reference for a probable typo
            def suggest(object, reference)
              if (match = METHOD_REFERENCE.match(reference))
                return if resolve(object, reference)

                suggest_method(object, match)
              elsif CONSTANT_REFERENCE.match?(reference)
                suggest_constant(object, reference)
              end
            end

            # @param object [YARD::CodeObjects::Base] documented object
            # @param match [MatchData] parts of a method reference
            # @return [String, nil] corrected method reference
            def suggest_method(object, match)
              namespace_name = match[:namespace]
              namespace = namespace_name ? resolve(object, namespace_name) : lexical_namespace(object)

              unless namespace
                suggestion = namespace_name && suggest_constant(object, namespace_name)

                return suggestion && "#{suggestion}#{match[:separator]}#{match[:name]}"
              end

              return unless namespace.is_a?(YARD::CodeObjects::NamespaceObject)

              scope = match[:separator] == '#' ? :instance : :class
              return if external_method?(namespace, match[:name], scope)

              candidates = namespace.meths(scope: scope).map { |meth| meth.name.to_s }
              # YARD does not resolve a method found more than one namespace up
              return if candidates.include?(match[:name])

              suggestion = spell_check(match[:name], candidates)

              suggestion && "#{namespace_name}#{match[:separator]}#{suggestion}"
            end

            # @param object [YARD::CodeObjects::Base] documented object
            # @param reference [String] constant reference
            # @return [String, nil] corrected constant reference
            def suggest_constant(object, reference)
              return if resolve(object, reference)
              return if runtime_constant?(reference)

              parent_name, _, name = reference.rpartition('::')

              if parent_name.empty?
                return if reference.start_with?('::')

                candidates = visible_constants(lexical_namespace(object))
              else
                parent = resolve(object, parent_name)
                return unless parent.is_a?(YARD::CodeObjects::NamespaceObject)

                candidates = constant_names(parent)
              end

              suggestion = spell_check(name, candidates)
              return unless suggestion

              parent_name.empty? ? suggestion : "#{parent_name}::#{suggestion}"
            end

            # @param object [YARD::CodeObjects::Base] lookup context
            # @param name [String] name to resolve
            # @return [YARD::CodeObjects::Base, nil] resolved registry object
            def resolve(object, name)
              YARD::Registry.resolve(object, name, true)
            end

            # @param object [YARD::CodeObjects::Base] documented object
            # @return [YARD::CodeObjects::Base, YARD::CodeObjects::Proxy] namespace links resolve against
            def lexical_namespace(object)
              object.is_a?(YARD::CodeObjects::NamespaceObject) ? object : object.namespace
            end

            # Root-level names are left out: a bare name near one of them is as
            # likely a constant of a gem YARD did not parse as it is a typo
            # @param namespace [YARD::CodeObjects::Base, YARD::CodeObjects::Proxy] innermost namespace
            # @return [Array<String>] constant names visible from it
            def visible_constants(namespace)
              names = []

              # `def CONST.name` and `class Unknown::Name` leave unresolved
              # namespaces, which have no children to list
              while namespace.is_a?(YARD::CodeObjects::NamespaceObject) && !namespace.root?
                names.concat(constant_names(namespace))
                namespace = namespace.namespace
              end

              names.uniq
            end

            # @param namespace [YARD::CodeObjects::NamespaceObject] namespace to list
            # @return [Array<String>] names of its constants, classes and modules
            def constant_names(namespace)
              namespace.children.filter_map do |child|
                child.name.to_s if %i[constant class module].include?(child.type)
              end
            end

            # A method may come from an ancestor YARD does not know about, so it
            # is checked against the loaded Ruby ancestors as well
            # @param namespace [YARD::CodeObjects::NamespaceObject] referenced namespace
            # @param name [String] referenced method name
            # @param scope [Symbol] :instance or :class
            # @return [Boolean] true when the method may exist outside the registry
            def external_method?(namespace, name, scope)
              ancestors = namespace.inheritance_tree(true).grep(YARD::CodeObjects::Proxy)
              ancestors << YARD::CodeObjects::Proxy.new(:root, 'Object')
              ancestors << YARD::CodeObjects::Proxy.new(:root, 'Class') if scope == :class

              ancestors.any? do |proxy|
                constant = runtime_constant(proxy.path)
                # An ancestor that is not loaded here may define anything
                next true unless constant.is_a?(Module)

                constant.method_defined?(name) || constant.private_method_defined?(name)
              end
            end

            # @param path [String] constant path
            # @return [Boolean] true when the constant is defined in this Ruby process
            def runtime_constant?(path)
              !runtime_constant(path).nil?
            end

            # @param path [String] constant path
            # @return [Object, nil] the constant's value, if it is loaded
            def runtime_constant(path)
              Object.const_get(path.delete_prefix('::'))
            rescue NameError
              nil
            end

            # @param name [String] misspelled name
            # @param candidates [Array<String>] known names
            # @return [String, nil] closest known name
            def spell_check(name, candidates)
              return if candidates.empty?

              DidYouMean::SpellChecker.new(dictionary: candidates).correct(name).first
            end
          end
        end
      end
    end
  end
end
