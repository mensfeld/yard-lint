# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module OverloadConsistency
          # Configuration for OverloadConsistency validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :overload_consistency
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
