# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
      # ApiTags validator module
        module ApiTags
          class << self
            # Unique identifier for this validator
            # @return [Symbol] validator identifier
            def id
              :api_tags
            end

            # Default configuration for this validator
            # @return [Hash] default configuration
            def defaults
              {
                'Enabled' => false,
                'Severity' => 'warning',
                'AllowedApis' => %w[public private internal]
              }
            end
          end
        end
      end
    end
  end
end
