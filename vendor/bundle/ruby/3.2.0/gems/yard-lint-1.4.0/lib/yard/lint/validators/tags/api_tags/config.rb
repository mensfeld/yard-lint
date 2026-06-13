# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ApiTags
          # Configuration for ApiTags validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :api_tags
            self.defaults = {
              'Enabled' => false,
              'Severity' => 'warning',
              'AllowedApis' => %w[public private internal]
            }.freeze
          end
        end
      end
    end
  end
end
