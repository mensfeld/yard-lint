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
                detected_style = offense[:detected_style]

                # Extract the corrected version based on detected style
                corrected = suggest_correction(type_string, detected_style)
                style_description = detected_style == 'short' ? 'long' : 'short'

                "Use #{style_description} collection syntax #{corrected} instead of " \
                  "#{type_string} in @#{tag_name} tag."
              end

              private

              # Suggests the corrected YARD syntax based on detected style
              # @param type_string [String] the incorrect type string
              # @param detected_style [String] the detected style ('short' or 'long')
              # @return [String] the suggested correction
              def suggest_correction(type_string, detected_style)
                if detected_style == 'short'
                  # Convert short to long: Hash<K, V> -> Hash{K => V} or {K => V} -> Hash{K => V}
                  convert_to_long(type_string)
                else
                  # Convert long to short: Hash{K => V} -> {K => V}
                  convert_to_short(type_string)
                end
              end

              # Converts short syntax to long syntax
              # @param type_string [String] the type string
              # @return [String] the converted type string
              def convert_to_long(type_string)
                if type_string.start_with?('{')
                  # {K => V} -> Hash{K => V}
                  "Hash#{type_string}"
                else
                  # Hash<K, V> -> Hash{K => V}
                  type_string.gsub(/Hash<(.+?)>/) do
                    types = ::Regexp.last_match(1)
                    # Split on comma, handle nested types
                    "Hash{#{types.sub(/,\s*/, ' => ')}}"
                  end
                end
              end

              # Converts long syntax to short syntax
              # @param type_string [String] the type string
              # @return [String] the converted type string
              def convert_to_short(type_string)
                # Hash{K => V} -> {K => V}
                type_string.sub(/^Hash/, '')
              end
            end
          end
        end
      end
    end
  end
end
