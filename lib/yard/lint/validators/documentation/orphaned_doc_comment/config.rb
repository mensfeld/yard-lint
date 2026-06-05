# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module OrphanedDocComment
          # Configuration for OrphanedDocComment validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :orphaned_doc_comment
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
