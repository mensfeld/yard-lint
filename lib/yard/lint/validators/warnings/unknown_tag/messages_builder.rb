# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Warnings
        module UnknownTag
          # Builds enhanced messages with "did you mean" suggestions for unknown tags
          class MessagesBuilder
            class << self
              # Dynamically fetch list of valid YARD meta-data tags from YARD::Tags::Library
              # This ensures we're always in sync with the installed YARD version
              # @return [Array<String>] array of tag names (without @ prefix)
              def known_tags
                @known_tags ||= begin
                  lib = ::YARD::Tags::Library.instance
                  lib.methods
                     .grep(/_tag$/)
                     .map { |m| m.to_s.sub(/_tag$/, '') }
                     .sort
                     .freeze
                end
              end

              # Dynamically fetch list of valid YARD directives from YARD::Tags::Library
              # This ensures we're always in sync with the installed YARD version
              # @return [Array<String>] array of directive names (without @! prefix)
              def known_directives
                @known_directives ||= begin
                  lib = ::YARD::Tags::Library.instance
                  lib.methods
                     .grep(/_directive$/)
                     .map { |m| m.to_s.sub(/_directive$/, '') }
                     .sort
                     .freeze
                end
              end

              # Combined list of all known tags and directives
              # @return [Array<String>] array of all valid tag and directive names
              def all_known_tags
                @all_known_tags ||= (known_tags + known_directives).freeze
              end
              # Build message with suggestion for unknown tag
              # @param offense [Hash] offense data with :message, :location (file), :line keys
              # @return [String] formatted message with suggestion if available
              def call(offense)
                message = offense[:message] || 'Unknown tag detected'

                # Extract the unknown tag name from the message
                # Format: "Unknown tag @tagname in file..."
                match = message.match(/Unknown tag @(\w+)/)
                return message unless match

                unknown_tag = match[1]

                # Find best suggestion using did_you_mean
                suggestion = find_suggestion(unknown_tag)

                if suggestion
                  # Replace just the descriptive part before "in file"
                  message.sub(/Unknown tag @\w+/, "Unknown tag @#{unknown_tag} (did you mean '@#{suggestion}'?)")
                else
                  message
                end
              end

              private

              # Find the best suggestion using DidYouMean spell checker
              # @param unknown_tag [String] the unknown tag name (without @ prefix)
              # @return [String, nil] suggested tag name or nil
              def find_suggestion(unknown_tag)
                return nil if unknown_tag.nil? || unknown_tag.empty?

                # Use DidYouMean::SpellChecker for smart suggestions
                spell_checker = DidYouMean::SpellChecker.new(dictionary: all_known_tags)
                suggestions = spell_checker.correct(unknown_tag)

                # If DidYouMean found suggestions, return the best one
                return suggestions.first unless suggestions.empty?

                # Otherwise, fallback to Levenshtein distance
                find_suggestion_fallback(unknown_tag)
              rescue StandardError => e
                # Fallback to simple Levenshtein distance if DidYouMean fails
                warn "DidYouMean failed: #{e.message}, using fallback" if ENV['DEBUG']
                find_suggestion_fallback(unknown_tag)
              end

              # Fallback suggestion finder using simple Levenshtein distance
              # @param unknown_tag [String] the unknown tag name
              # @return [String, nil] suggested tag name or nil
              def find_suggestion_fallback(unknown_tag)
                # Calculate Levenshtein distance for each tag
                distances = all_known_tags.map do |tag|
                  [tag, levenshtein_distance(unknown_tag, tag)]
                end

                # Sort by distance and get the closest match
                best_match = distances.min_by { |_tag, distance| distance }

                # Only suggest if the distance is reasonable (less than half the length)
                return nil unless best_match

                tag, distance = best_match
                max_distance = [unknown_tag.length, tag.length].max / 2

                distance <= max_distance ? tag : nil
              end

              # Calculate Levenshtein distance between two strings
              # @param str1 [String] first string
              # @param str2 [String] second string
              # @return [Integer] Levenshtein distance
              def levenshtein_distance(str1, str2)
                return str2.length if str1.empty?
                return str1.length if str2.empty?

                matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }

                (0..str1.length).each { |i| matrix[i][0] = i }
                (0..str2.length).each { |j| matrix[0][j] = j }

                (1..str1.length).each do |i|
                  (1..str2.length).each do |j|
                    cost = str1[i - 1] == str2[j - 1] ? 0 : 1
                    matrix[i][j] = [
                      matrix[i - 1][j] + 1,      # deletion
                      matrix[i][j - 1] + 1,      # insertion
                      matrix[i - 1][j - 1] + cost # substitution
                    ].min
                  end
                end

                matrix[str1.length][str2.length]
              end
            end
          end
        end
      end
    end
  end
end
