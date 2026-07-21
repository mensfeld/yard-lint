# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module DuplicateNamespaceComment
          # Configuration for DuplicateNamespaceComment validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :duplicate_namespace_comment
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning'
            }.freeze
          end
        end
      end
    end
  end
end
