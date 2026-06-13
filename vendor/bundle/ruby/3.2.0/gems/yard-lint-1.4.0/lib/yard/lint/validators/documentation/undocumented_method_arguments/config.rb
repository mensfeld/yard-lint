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
              'Severity' => 'warning'
            }.freeze
          end
        end
      end
    end
  end
end
