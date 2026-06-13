# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module MarkdownSyntax
          # Configuration for MarkdownSyntax validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :markdown_syntax
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
