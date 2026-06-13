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
                elsif type_string.start_with?('<')
                  # <String> -> Array<String>
                  "Array#{type_string}"
                elsif type_string.start_with?('(')
                  # (String, Integer) -> Array(String, Integer)
                  "Array#{type_string}"
                else
                  # Hash<K, V> -> Hash{K => V}, handling nested generics with
                  # balanced-bracket splitting so the suggestion stays valid.
                  convert_hash_short_to_long(type_string)
                end
              end

              # Converts Hash<K, V> to Hash{K => V}, recursing into the key and
              # value and splitting on the top-level comma so nested types like
              # Hash<Symbol, Hash<String, Integer>> are not mangled.
              # @param type_string [String] the type string
              # @return [String] the converted type string
              def convert_hash_short_to_long(type_string)
                match = type_string.match(/\AHash<(.+)>\z/m)
                return type_string unless match

                key, value = split_top_level(match[1])
                return type_string unless value

                "Hash{#{convert_hash_short_to_long(key.strip)} => " \
                  "#{convert_hash_short_to_long(value.strip)}}"
              end

              # Splits a generic body on its first top-level comma, respecting
              # nested <>, {}, and () so nested generics are kept intact.
              # @param str [String] the inside of a generic (without the brackets)
              # @return [Array] [key, value], or [str, nil] when there is no
              #   top-level comma
              def split_top_level(str)
                depth = 0
                str.each_char.with_index do |char, index|
                  case char
                  when '<', '{', '(' then depth += 1
                  when '>', '}', ')' then depth -= 1
                  when ','
                    return [str[0...index], str[(index + 1)..]] if depth.zero?
                  end
                end
                [str, nil]
              end

              # Converts long syntax to short syntax
              # @param type_string [String] the type string
              # @return [String] the converted type string
              def convert_to_short(type_string)
                # Hash{K => V} -> {K => V} or Array<String> -> <String> or Array(S, I) -> (S, I)
                type_string.sub(/^(Hash|Array)/, '')
              end
            end
          end
        end
      end
    end
  end
end
