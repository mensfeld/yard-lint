# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module NonAsciiType
          # Configuration for NonAsciiType validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :non_ascii_type
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              'ValidatedTags' => %w[param option return yieldreturn yieldparam]
            }.freeze
          end
        end
      end
    end
  end
end
