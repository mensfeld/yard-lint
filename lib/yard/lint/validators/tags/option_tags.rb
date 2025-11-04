# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
      # OptionTags validator module
        module OptionTags
          class << self
            # Unique identifier for this validator
            # @return [Symbol] validator identifier
            def id
              :option_tags
            end

            # Default configuration for this validator
            # @return [Hash] default configuration
            def defaults
              {
                'Enabled' => true,
                'Severity' => 'warning',
                'ParameterNames' => %w[options opts kwargs]
              }
            end
          end
        end
      end
    end
  end
end
