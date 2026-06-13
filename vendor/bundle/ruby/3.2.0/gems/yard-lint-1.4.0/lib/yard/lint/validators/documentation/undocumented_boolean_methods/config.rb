# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedBooleanMethods
          # Configuration for UndocumentedBooleanMethods validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :undocumented_boolean_methods
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning'
            }.freeze
          end
        end
      end
    end
  end
end
