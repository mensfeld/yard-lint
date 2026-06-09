# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module LineLength
          # Configuration for LineLength validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :line_length
            self.defaults = {
              'Enabled' => false,
              'Severity' => 'convention',
              'MaxLength' => 120
            }.freeze
          end
        end
      end
    end
  end
end
