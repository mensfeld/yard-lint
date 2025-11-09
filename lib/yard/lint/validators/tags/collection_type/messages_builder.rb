# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module CollectionType
          # Builds human-readable messages for CollectionType violations
          class MessagesBuilder
            class << self
              # Formats a violation message
              # @param offense [Hash] the offense details
              # @return [String] formatted message
              def call(offense)
                type_string = offense[:type_string]
                tag_name = offense[:tag_name]

                # Extract the corrected version
                corrected = suggest_correction(type_string)

                "Use YARD collection syntax #{corrected} instead of #{type_string} " \
                  "in @#{tag_name} tag. YARD uses Hash{K => V} syntax for hashes."
              end

              private

              # Suggests the corrected YARD syntax
              # @param type_string [String] the incorrect type string
              # @return [String] the suggested correction
              def suggest_correction(type_string)
                # Convert Hash<K, V> to Hash{K => V}
                type_string.gsub(/Hash<(.+?)>/) do
                  types = ::Regexp.last_match(1)
                  # Split on comma, handle nested types
                  "Hash{#{types.sub(/,\s*/, ' => ')}}"
                end
              end
            end
          end
        end
      end
    end
  end
end
