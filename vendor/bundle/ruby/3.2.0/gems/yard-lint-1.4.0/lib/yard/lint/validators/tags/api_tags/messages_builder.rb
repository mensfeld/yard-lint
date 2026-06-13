# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Tags validators - validate YARD tag quality and consistency
      module Tags
        module ApiTags
          # Builds messages for API tag offenses
          class MessagesBuilder
            class << self
              # Build message for API tag offense
              # @param offense [Hash] offense data with :status and :object_name keys
              # @return [String] formatted message
              def call(offense)
                if offense[:status] == 'missing'
                  "Public object `#{offense[:object_name]}` is missing @api tag"
                else
                  api_value = offense[:api_value] || offense[:status]&.sub('invalid:', '')
                  "Object `#{offense[:object_name]}` has invalid @api tag value: '#{api_value}'"
                end
              end
            end
          end
        end
      end
    end
  end
end
