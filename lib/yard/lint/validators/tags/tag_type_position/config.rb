# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagTypePosition
          # Configuration for TagTypePosition validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :tag_type_position
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'convention',
              'CheckedTags' => %w[param option],
              'EnforcedStyle' => 'type_after_name' # 'type_after_name' (YARD standard) or 'type_first'
            }.freeze
          end
        end
      end
    end
  end
end
