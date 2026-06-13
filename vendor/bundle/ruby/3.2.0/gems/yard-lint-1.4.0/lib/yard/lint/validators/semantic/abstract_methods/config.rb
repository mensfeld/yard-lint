# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Semantic
        module AbstractMethods
          # Configuration for AbstractMethods validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :abstract_methods
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              'AllowedImplementations' => [
                'raise NotImplementedError',
                'raise NotImplementedError, ".+"'
              ]
            }.freeze
          end
        end
      end
    end
  end
end
