# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InvalidTypes
          # Runs a query that will pick all the objects that have invalid type definitions
          # By invalid we mean, that they are not classes nor any of the allowed defaults or
          # exclusions.
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # All non-class yard types that are considered valid
            ALLOWED_DEFAULTS = %w[
              false
              true
              nil
              self
              void
              undefined
              unspecified
              unknown
              Boolean
            ].freeze

            private_constant :ALLOWED_DEFAULTS

            # Execute query for a single object during in-process execution.
            # Checks for invalid type definitions in tags.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              checked_tags = config_or_default('ValidatedTags')
              extra_types = config_or_default('ExtraTypes')
              strict = config_or_default('StrictConstantNames')
              allowed_types = ALLOWED_DEFAULTS + extra_types

              # Collect per-tag violations to surface in the offense message.
              # Each entry is "tagname param_name:Type1,Type2" (param_name omitted when nil).
              tag_violations = all_typed_tags(object.docstring, checked_tags).filter_map do |tag|
                bad = (tag_data(tag).types || [])
                        .compact
                        .flat_map { |type| extract_type_names(type) }
                        .uniq
                        .reject { |type| allowed_types.include?(type) }
                        .reject { |type| type_defined?(type, strict: strict) }
                        .reject { |type| type.include?('#') }
                next if bad.empty?

                label = tag.name ? "@#{tag.tag_name} #{tag.name}" : "@#{tag.tag_name}"
                "#{label}:#{bad.join(',')}"
              end

              return if tag_violations.empty?

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts tag_violations.join('|')
            end

            private

            # Extract individual type names from a compound type string.
            # Instead of stripping all syntax characters and concatenating (which
            # turns "Array<self>" into "Arrayself"), this splits on syntax boundaries
            # and returns each type name individually.
            # @param type_str [String] the raw type string (e.g., "Array<self>", "Hash{Symbol => String}")
            # @return [Array<String>] individual type names (e.g., ["Array", "self"], ["Hash", "Symbol", "String"])
            def extract_type_names(type_str)
              type_str.split(/[=><,{}\s();]+/).reject(&:empty?)
            end

            # Check if a type is defined in Ruby runtime or YARD registry
            # In in-process mode, parsed classes are in YARD registry but not loaded into Ruby
            # @param type [String] type name to check
            # @param strict [Boolean] when true, a syntactically valid but unknown
            #   constant name (e.g. a typo) is treated as undefined instead of recognized
            # @return [Boolean] true if type is defined (or at least recognized as a valid type)
            def type_defined?(type, strict: false)
              # Symbol and string literal types (:foo, "bar") are valid hash key notations
              return true if type.start_with?(':', '"', "'")

              # Check Ruby runtime first.
              # const_defined? returns true (loaded constant), false (valid name but
              # not loaded), or raises NameError (invalid constant syntax).
              begin
                const_result = Kernel.const_defined?(type)
              rescue NameError
                # Invalid constant name syntax (e.g., "foo<bar>" or names with special chars)
                # These aren't valid Ruby constants, so we can't check them this way
                const_result = nil
              end

              if strict
                # Strict mode: only a constant actually loaded in this process
                # (Ruby core/stdlib) is accepted outright. A valid-but-unloaded
                # name (const_result == false) or invalid syntax (nil) still gets
                # the YARD registry check below, so codebase-defined types pass but
                # unknown CamelCase names (typos) are flagged.
                return true if const_result == true
              else
                # Lenient (default): any syntactically valid constant name is
                # accepted, because YARD does not load the project's code so most
                # real types are not const_defined? in this process.
                return true unless const_result.nil?
              end

              # Check YARD registry (for classes defined in parsed files)
              # This may fail for malformed type strings or registry issues
              !YARD::Registry.resolve(nil, type).nil?
            rescue NameError
              # Type couldn't be resolved - it's not defined
              false
            end
          end
        end
      end
    end
  end
end
