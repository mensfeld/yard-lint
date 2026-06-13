# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedOptions
          # Configuration for UndocumentedOptions validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :undocumented_options
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
