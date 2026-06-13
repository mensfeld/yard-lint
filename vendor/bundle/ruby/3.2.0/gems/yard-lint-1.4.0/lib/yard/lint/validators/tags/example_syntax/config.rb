# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleSyntax
          # Configuration for ExampleSyntax validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :example_syntax
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
