# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module MissingReturn
          # Configuration for MissingReturn validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :missing_return
            self.defaults = {
              'Enabled' => false, # Disabled by default (opt-in validator)
              'Severity' => 'warning',
              'ExcludedMethods' => [
                'initialize' # Exclude all initialize methods by default
              ]
            }.freeze
          end
        end
      end
    end
  end
end
