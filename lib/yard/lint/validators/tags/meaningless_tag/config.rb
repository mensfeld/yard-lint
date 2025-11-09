# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module MeaninglessTag
          # Configuration for MeaninglessTag validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :meaningless_tag
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              'CheckedTags' => %w[param option],
              'InvalidObjectTypes' => %w[class module constant]
            }.freeze
          end
        end
      end
    end
  end
end
