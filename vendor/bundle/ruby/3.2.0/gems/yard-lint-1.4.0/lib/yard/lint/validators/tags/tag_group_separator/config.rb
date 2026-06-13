# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagGroupSeparator
          # Configuration for TagGroupSeparator validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :tag_group_separator
            self.defaults = {
              'Enabled' => false,
              'Severity' => 'convention',
              'TagGroups' => {
                'param' => %w[param option],
                'return' => %w[return],
                'error' => %w[raise throws],
                'example' => %w[example],
                'meta' => %w[see note todo deprecated since version api],
                'yield' => %w[yield yieldparam yieldreturn]
              },
              'RequireAfterDescription' => false
            }.freeze
          end
        end
      end
    end
  end
end
