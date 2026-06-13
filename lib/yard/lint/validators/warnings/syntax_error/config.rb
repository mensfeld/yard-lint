# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Validators for checking YARD warnings
      module Warnings
        # Validator for detecting files YARD could not parse
        module SyntaxError
          # Configuration for SyntaxError validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :syntax_error
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
