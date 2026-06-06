# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module MissingYield
          # Configuration for MissingYield validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :missing_yield
            self.defaults = {
              'Enabled' => false,
              'Severity' => 'warning'
            }.freeze
          end
        end
      end
    end
  end
end
