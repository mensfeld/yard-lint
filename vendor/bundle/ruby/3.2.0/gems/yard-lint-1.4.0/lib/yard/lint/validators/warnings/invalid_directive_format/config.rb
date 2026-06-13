# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Validators for checking YARD warnings
      module Warnings
        # Validator for detecting invalid directive formats
        module InvalidDirectiveFormat
          # Configuration for InvalidDirectiveFormat validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :invalid_directive_format
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
