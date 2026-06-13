# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InvalidTypes
          # Configuration for InvalidTypes validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :invalid_types
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              'ValidatedTags' => %w[param option return yieldreturn],
              'ExtraTypes' => []
            }.freeze
          end
        end
      end
    end
  end
end
