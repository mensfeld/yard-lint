# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ForbiddenTags
          # Configuration for ForbiddenTags validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :forbidden_tags
            self.defaults = {
              'Enabled' => false,
              'Severity' => 'convention',
              'ForbiddenPatterns' => []
            }.freeze
          end
        end
      end
    end
  end
end
