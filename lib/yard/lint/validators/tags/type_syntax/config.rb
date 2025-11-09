# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TypeSyntax
          # Configuration for TypeSyntax validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :type_syntax
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              'ValidatedTags' => %w[param option return yieldreturn]
            }.freeze
          end
        end
      end
    end
  end
end
