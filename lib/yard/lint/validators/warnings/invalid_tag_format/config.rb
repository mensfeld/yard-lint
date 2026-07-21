# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module InvalidTagFormat
          # Configuration for InvalidTagFormat validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :invalid_tag_format
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
