# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
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
