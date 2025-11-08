# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedObjects
          # Configuration for UndocumentedObjects validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :undocumented_objects
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              'AllowEmptyInitialize' => true
            }.freeze
            self.combines_with = ['Documentation/UndocumentedBooleanMethods'].freeze
          end
        end
      end
    end
  end
end
