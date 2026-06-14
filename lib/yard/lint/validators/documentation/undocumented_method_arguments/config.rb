# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedMethodArguments
          # Configuration for UndocumentedMethodArguments validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :undocumented_method_arguments
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              'AllowedParentClasses' => [],
              'AllowedMethods' => [],
              # Opt-in: match each parameter to a @param tag by name instead of
              # only comparing counts. Catches a misnamed @param (e.g. `@param
              # wrong` for `def push(item)`) that the count check accepts. Off by
              # default to preserve the lenient count-based behaviour.
              'CheckParameterNames' => false,
              # Opt-in: skip methods with no documentation at all and let
              # Documentation/UndocumentedObjects report them, avoiding a second
              # offense for the same fully-undocumented method. Off by default.
              'SkipFullyUndocumented' => false
            }.freeze
          end
        end
      end
    end
  end
end
