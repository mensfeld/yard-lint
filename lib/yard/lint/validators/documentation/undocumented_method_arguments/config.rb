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
              # Match each parameter to a @param tag by name (default). Catches a
              # misnamed @param (e.g. `@param wrong` for `def push(item)`) that a
              # count-only check would accept. Set to false to fall back to the
              # lenient count-only comparison.
              'CheckParameterNames' => true,
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
