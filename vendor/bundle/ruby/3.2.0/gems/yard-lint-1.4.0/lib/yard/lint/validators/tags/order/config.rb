# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module Order
          # Configuration for Order validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :order
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'convention',
              'EnforcedOrder' => %w[
                param
                option
                yield
                yieldparam
                yieldreturn
                return
                raise
                see
                example
                note
                todo
              ]
            }.freeze
          end
        end
      end
    end
  end
end
