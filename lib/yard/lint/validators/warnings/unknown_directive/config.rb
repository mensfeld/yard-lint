# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module UnknownDirective
          # Configuration for UnknownDirective validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :unknown_directive
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'error'
            }.freeze
          end
        end
      end
    end
  end
end
