# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InvalidTypes
          # Builds messages for invalid tag types offenses
          class MessagesBuilder
            class << self
              # Build message for invalid tag types
              # @param offense [Hash] offense data with :method_name and :tag_violations keys
              # @return [String] formatted message
              def call(offense)
                violations = offense[:tag_violations]

                if violations&.any?
                  details = violations.map do |v|
                    label = v[:param] ? "#{v[:tag]} #{v[:param]}" : v[:tag]
                    types = v[:types].map { |t| "`#{t}`" }.join(', ')
                    "#{label}: #{types}"
                  end.join('; ')

                  "The `#{offense[:method_name]}` has invalid type(s): #{details}"
                else
                  "The `#{offense[:method_name]}` has at least one tag with an invalid type definition."
                end
              end
            end
          end
        end
      end
    end
  end
end
