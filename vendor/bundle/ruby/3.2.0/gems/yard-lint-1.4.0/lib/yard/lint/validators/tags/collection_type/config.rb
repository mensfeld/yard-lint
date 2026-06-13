# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module CollectionType
          # Configuration for CollectionType validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :collection_type
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'convention',
              'ValidatedTags' => %w[param option return yieldreturn],
              'EnforcedStyle' => 'long' # 'long' (Hash{K => V}) or 'short' ({K => V})
            }.freeze
          end
        end
      end
    end
  end
end
