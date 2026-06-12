# frozen_string_literal: true

module Yard
  module Lint
    # Validators for checking different aspects of YARD documentation
    module Validators
      # Base YARD validator class
      class Base
        # Class-level settings for in-process execution
        # These must be set on each subclass, not on Base
        @in_process_enabled = nil
        @in_process_visibility = nil

        attr_reader :config, :selection

        class << self
          # Declare that this validator supports in-process execution
          # @param visibility [Symbol] visibility filter for objects (:public or :all)
          #   :public - only include public methods (default, no --private/--protected)
          #   :all - include all methods (equivalent to --private --protected)
          # @return [void]
          # @example
          #   class Validator < Base
          #     in_process visibility: :all
          #   end
          def in_process(visibility: :public)
            @in_process_enabled = true
            @in_process_visibility = visibility
          end

          # Check if this validator supports in-process execution
          # @return [Boolean]
          def in_process?
            @in_process_enabled == true
          end

          # Get the visibility setting for in-process execution
          # @return [Symbol, nil] :public, :all, or nil if not set
          def in_process_visibility
            @in_process_visibility
          end

          # Get the validator name from the class namespace
          # @return [String, nil] validator name like 'Tags/Order' or nil
          # @example
          #   Yard::Lint::Validators::Tags::Order::Validator.validator_name
          #   # => 'Tags/Order'
          def validator_name
            name&.split('::')&.then do |parts|
              idx = parts.index('Validators')
              return nil unless idx && parts[idx + 1] && parts[idx + 2]

              "#{parts[idx + 1]}/#{parts[idx + 2]}"
            end
          end
        end

        # @param config [Yard::Lint::Config] configuration object
        # @param selection [Array<String>] array with ruby files we want to check
        def initialize(config, selection)
          @config = config
          @selection = selection
        end

        # Execute query for a single object during in-process execution.
        # Override this method in validators that support in-process execution.
        # @param object [YARD::CodeObjects::Base] the code object to query
        # @param collector [Executor::ResultCollector] collector for output
        # @return [void]
        # @example
        #   def in_process_query(object, collector)
        #     return unless object.docstring.all.empty?
        #     collector.puts "#{object.file}:#{object.line}: #{object.title}"
        #   end
        def in_process_query(object, collector)
          raise NotImplementedError, "#{self.class} must implement in_process_query for in-process execution"
        end

        private

        # Collect tags matching the given tag names from a docstring, including
        # tags nested inside @overload blocks. YARD stores @overload inner tags
        # on the overload's own docstring, so they are invisible to
        # `docstring.tags` - this helper traverses them.
        # @param docstring [YARD::Docstring] the docstring to search
        # @param tag_names [Array<String>] tag names to collect (e.g., %w[param return])
        # @return [Array<YARD::Tags::Tag>] matching tags from the docstring and any overloads
        def all_typed_tags(docstring, tag_names)
          tags = docstring.tags.select { |tag| tag_names.include?(tag.tag_name) }

          docstring.tags(:overload).each do |overload|
            overload.docstring.tags.each do |tag|
              tags << tag if tag_names.include?(tag.tag_name)
            end
          end

          tags
        end

        # Tracks docstring locations already processed by this validator
        # instance. Objects generated from a single comment block (e.g. the
        # reader and writer created by attr_accessor) share one docstring;
        # content-scanning validators use this to report each docstring once.
        # @param object [YARD::CodeObjects::Base] the code object to check
        # @return [Boolean] true if this object's docstring was already seen
        def duplicate_docstring?(object)
          @scanned_docstrings ||= Set.new
          key = [object.file, object.docstring.line_range&.first || object.line]

          !@scanned_docstrings.add?(key)
        end

        # Returns the tag that actually carries a tag's types and description.
        # For most tags that is the tag itself, but @option tags wrap their
        # data in a nested pair tag - tag.types and tag.text are nil on the
        # OptionTag itself, with the documented option living on tag.pair.
        # @param tag [YARD::Tags::Tag] tag whose data holder should be resolved
        # @return [YARD::Tags::Tag] the tag holding types/text data
        def tag_data(tag)
          tag.respond_to?(:pair) && tag.pair ? tag.pair : tag
        end

        # Checks whether the object's enclosing class (or the object itself if it is
        # a class) has a superclass that appears in the validator's AllowedParentClasses
        # configuration list. When true, validators skip the object so that classes
        # inheriting from common base classes (e.g. StandardError, ApplicationRecord)
        # are not flagged.
        #
        # Matching is done on YARD's resolved superclass path, which is always the
        # fully-qualified name (e.g. "ActiveRecord::Base"). Entries in
        # AllowedParentClasses are matched exactly, so callers must use the same form
        # (e.g. "ActiveRecord::Base", not "Base").
        #
        # For method objects the enclosing namespace's superclass is checked. For
        # class objects the class itself is checked. Other object types always return
        # false so that modules and constants are unaffected.
        #
        # @param object [YARD::CodeObjects::Base] the code object to check
        # @return [Boolean] true if the object should be skipped
        def parent_class_allowed?(object)
          allowed = Array(config_or_default('AllowedParentClasses'))
          return false if allowed.empty?

          klasses = case object.type
                    when :class
                      # Check the class's own superclass; also check the enclosing class's
                      # superclass so that nested classes and constants inside an allowed
                      # parent class are exempted as well.
                      [object, object.namespace].select { |k| k.respond_to?(:superclass) }
                    when :method, :constant
                      ns = object.namespace
                      ns.respond_to?(:superclass) ? [ns] : []
                    else
                      []
                    end

          return false if klasses.empty?

          klasses.any? do |klass|
            superclass = klass.superclass
            next false if superclass.nil?

            superclass_path = superclass.respond_to?(:path) ? superclass.path.to_s : superclass.to_s
            next false if superclass_path.empty?
            # Every Ruby class without an explicit parent implicitly inherits from Object,
            # so matching it would exempt all classes — never the intent.
            # BasicObject is the root of the hierarchy and is guarded for the same reason.
            next false if superclass_path == 'Object' || superclass_path == 'BasicObject'

            allowed.any? { |a| superclass_path == a.to_s }
          end
        end

        # Checks whether the method object's name matches any entry in the validator's
        # AllowedMethods configuration list. When true, the validator should skip the
        # object without reporting an offense.
        #
        # Three pattern forms are supported (matching ExcludedMethods convention):
        #   - Exact name:    'call'          — matches any arity
        #   - Arity:         'initialize/1'  — matches only the given parameter count
        #                                      (required + optional, excluding * and &)
        #   - Regex:         '/^perform/'    — matches against the bare method name
        #
        # Invalid regex patterns are silently ignored. The empty regex '//' is always
        # rejected (it would match every method, making the option useless).
        #
        # @param object [YARD::CodeObjects::Base] the code object to check
        # @return [Boolean] true if the method should be skipped
        def method_allowed?(object)
          return false unless object.type == :method

          allowed = Array(config_or_default('AllowedMethods'))
            .compact
            .map { |p| p.to_s.strip }
            .reject(&:empty?)
            .reject { |p| p == '//' }
          return false if allowed.empty?

          method_name = object.name.to_s
          arity = object.parameters.reject { |p| p[0].to_s.start_with?('*', '&') }.size

          allowed.any? { |pattern| matches_method_pattern?(method_name, arity, pattern) }
        end

        # Matches a single AllowedMethods/ExcludedMethods pattern against a method.
        # @param method_name [String] bare method name (e.g. "call")
        # @param arity [Integer] parameter count (required + optional, no * or &)
        # @param pattern [String] one entry from the AllowedMethods list
        # @return [Boolean]
        def matches_method_pattern?(method_name, arity, pattern)
          case pattern
          when %r{^/(.+)/$}
            regex_str = Regexp.last_match(1)
            return false if regex_str.empty?

            begin
              Regexp.new(regex_str).match?(method_name)
            rescue RegexpError
              false
            end
          when %r{^[^/]+/\d+$}
            pattern_name, pattern_arity_str = pattern.split('/', 2)
            method_name == pattern_name && arity == pattern_arity_str.to_i
          else
            method_name == pattern
          end
        end

        # Retrieves configuration value with fallback to default
        # Automatically determines the validator name from the class namespace
        #
        # @param key [String] the configuration key to retrieve
        # @return [Object] the configured value or default value from the validator's Config.defaults
        # @example Usage in a validator (e.g., Tags::RedundantParamDescription)
        #   def config_articles
        #     config_or_default("Articles")
        #   end
        # @note The validator name is automatically extracted from the class namespace.
        #   For example, Yard::Lint::Validators::Tags::RedundantParamDescription::Validator
        #   becomes 'Tags/RedundantParamDescription'
        def config_or_default(key)
          validator_name = self.class.name&.split('::')&.then do |parts|
            idx = parts.index('Validators')
            next nil unless idx && parts[idx + 1] && parts[idx + 2]

            "#{parts[idx + 1]}/#{parts[idx + 2]}"
          end

          # Get the validator module's Config class
          validator_config_class = begin
            # Get parent module (e.g., Yard::Lint::Validators::Tags::RedundantParamDescription)
            parent_module = self.class.name.split('::')[0..-2].join('::')
            Object.const_get("#{parent_module}::Config")
          rescue NameError
            nil
          end

          defaults = validator_config_class&.defaults || {}

          return defaults[key] unless validator_name

          value = config.validator_config(validator_name, key)
          # A nil? check (not ||) so that explicitly configured false values
          # are honored instead of falling back to a truthy default
          value.nil? ? defaults[key] : value
        end
      end
    end
  end
end
