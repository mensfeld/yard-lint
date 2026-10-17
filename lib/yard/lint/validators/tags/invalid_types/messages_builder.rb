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
                  details = violations.group_by { |v| v[:param] ? "#{v[:tag]} #{v[:param]}" : v[:tag] }
                                      .map do |label, entries|
                    "#{label}: #{entries.map { |v| describe_types(v) }.join(', ')}"
                  end.join('; ')

                  "The `#{offense[:method_name]}` has invalid type(s): #{details}"
                else
                  "The `#{offense[:method_name]}` has at least one tag with an invalid type definition."
                end
              end

              private

              # @param violation [Hash] entry with :types (invalid names) and :type_string (full type, may be nil)
              # @return [String] the invalid names, plus the full type when it differs from them
              def describe_types(violation)
                names = violation[:types].map { |t| "`#{t}`" }.join(', ')
                type_string = violation[:type_string]
                return names if type_string.nil? || violation[:types] == [type_string]

                "#{names} in `#{type_string}`"
              end
            end
          end
        end
      end
    end
  end
end
