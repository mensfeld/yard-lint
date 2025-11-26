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
              allowed_types = ALLOWED_DEFAULTS + extra_types

              # Sanitize type string (remove type syntax characters)
              sanitize = ->(type) { type.tr('=><>,{} ', '') }

              # Check for invalid types
              invalid_types = object.docstring.tags
                                    .select { |tag| checked_tags.include?(tag.tag_name) }
                                    .flat_map(&:types)
                                    .compact
                                    .uniq
                                    .map(&sanitize)
                                    .reject { |type| allowed_types.include?(type) }
                                    .reject { |type| type_defined?(type) }
                                    .reject { |type| type.include?('#') }

              return if invalid_types.empty?

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
            end

            private

            # Check if a type is defined in Ruby runtime or YARD registry
            # In in-process mode, parsed classes are in YARD registry but not loaded into Ruby
            # @param type [String] type name to check
            # @return [Boolean] true if type is defined (or at least recognized as a valid type)
            def type_defined?(type)
              # Symbol types like :foo are valid YARD documentation notations
              # They document that a method accepts specific symbol values
              return true if type.start_with?(':')

              # Check Ruby runtime first
              # The shell query uses: !(Kernel.const_defined?(type) rescue nil).nil?
              # This means: if const_defined? returns ANY value (true or false, not nil),
              # the type is considered "recognized" and should not be flagged as invalid.
              # This allows common types like "Boolean" which aren't actual Ruby classes
              # but are still recognized by Ruby as valid constant names to check.
              begin
                const_result = Kernel.const_defined?(type)
              rescue StandardError
                const_result = nil
              end
              return true unless const_result.nil?

              # Check YARD registry (for classes defined in parsed files)
              !YARD::Registry.resolve(nil, type).nil?
            rescue StandardError
              false
            end
          end
        end
      end
    end
  end
end
