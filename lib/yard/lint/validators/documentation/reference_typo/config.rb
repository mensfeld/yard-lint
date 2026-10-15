# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module ReferenceTypo
          # Configuration for ReferenceTypo validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :reference_typo
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
