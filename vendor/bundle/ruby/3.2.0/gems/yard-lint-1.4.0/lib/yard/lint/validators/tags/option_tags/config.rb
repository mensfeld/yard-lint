# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module OptionTags
          # Configuration for OptionTags validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :option_tags
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              'ParameterNames' => %w[options opts kwargs]
            }.freeze
          end
        end
      end
    end
  end
end
