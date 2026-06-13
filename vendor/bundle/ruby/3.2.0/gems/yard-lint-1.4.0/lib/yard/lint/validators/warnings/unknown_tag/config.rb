# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Validators for checking YARD warnings
      module Warnings
        # Validator for detecting unknown tags in documentation
        module UnknownTag
          # Configuration for UnknownTag validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :unknown_tag
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
