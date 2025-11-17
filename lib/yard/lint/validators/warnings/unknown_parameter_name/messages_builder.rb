# frozen_string_literal: true

require 'did_you_mean'
require 'shellwords'

module Yard
  module Lint
    module Validators
      module Warnings
        module UnknownParameterName
          # Builds enhanced messages with "did you mean" suggestions
          class MessagesBuilder
            class << self
              # Build message with suggestion for unknown parameter
              # @param offense [Hash] offense data with :message, :location (file), :line keys
              # @return [String] formatted message with suggestion if available
              def call(offense)
                message = offense[:message] || 'UnknownParameterName detected'

                # Extract the unknown parameter name from the message
                # Format: "@param tag has unknown parameter name: param_name"
                match = message.match(/@param tag has unknown parameter name: (\w+)/)
                return message unless match

                unknown_param = match[1]

                # Get actual parameters for the method at this location
                # Note: offense[:location] contains the file path
                file = offense[:location]
                line = offense[:line]
                actual_params = fetch_actual_parameters(file, line)
                return message if actual_params.empty?

                # Find best suggestion using did_you_mean
                suggestion = find_suggestion(unknown_param, actual_params)

                if suggestion
                  "#{message} (did you mean '#{suggestion}'?)"
                else
                  message
                end
              end

              private

              # Fetch actual method parameters from YARD at the given location
              # @param file [String] file path
              # @param line [Integer, String] line number
              # @return [Array<String>] array of actual parameter names
              def fetch_actual_parameters(file, line)
                return [] unless file && line

                line_num = line.to_i

                # First, try to parse directly from the Ruby source file
                # This is faster and doesn't require YARD to be fully loaded
                params = parse_parameters_from_source(file, line_num)
                return params unless params.empty?

                # Fallback: Query YARD list for the method
                # This requires YARD to parse the file first
                fetch_parameters_via_yard(file, line_num)
              rescue StandardError => e
                # If anything goes wrong, just return empty array (no suggestion)
                warn "Failed to fetch parameters: #{e.message}" if ENV['DEBUG']
                []
              end

              # Parse method parameters directly from Ruby source file
              # @param file [String] file path
              # @param line [Integer] line number (approximate location of method)
              # @return [Array<String>] array of parameter names
              def parse_parameters_from_source(file, line)
                return [] unless File.exist?(file)

                # Calculate the search range (line numbers are 1-indexed)
                start_line = [(line - 15), 1].max
                end_line = line + 5

                # Only read the lines in the relevant range to avoid loading the whole file
                lines = []
                current_line_num = 1
                File.foreach(file) do |source_line|
                  lines << source_line if current_line_num >= start_line && current_line_num <= end_line
                  break if current_line_num > end_line

                  current_line_num += 1
                end

                # Search for method definition in the collected lines
                in_multiline_def = false
                param_lines = []

                lines.each do |source_line|
                  # Match single-line method definitions: def method_name(param1, param2)
                  if source_line =~ /^\s*def\s+\w+\s*\((.*?)\)/
                    params_str = ::Regexp.last_match(1)
                    return extract_parameter_names(params_str)
                  # Match start of multi-line method definition: def method_name(
                  elsif source_line =~ /^\s*def\s+\w+\s*\((.*)$/
                    in_multiline_def = true
                    param_lines << ::Regexp.last_match(1)
                    next
                  elsif in_multiline_def
                    param_lines << source_line.strip
                    # Check if this line closes the parameter list
                    if source_line.include?(')')
                      # Join all lines and extract params
                      params_str = param_lines.join(' ')
                      # Remove trailing ')' and anything after it
                      params_str = params_str[/\A(.*?)\)/, 1] || params_str
                      return extract_parameter_names(params_str)
                    end
                  elsif source_line.match?(/^\s*def\s+\w+\s*$/)
                    # Method with no parameters
                    return []
                  end
                end

                []
              rescue StandardError => e
                warn "Failed to parse source: #{e.message}" if ENV['DEBUG']
                []
              end

              # Extract parameter names from a parameter string
              # Handles various parameter formats: regular, default values, splat, keyword, block
              # @param params_str [String] parameter string from method signature
              # @return [Array<String>] array of parameter names
              def extract_parameter_names(params_str)
                return [] if params_str.nil? || params_str.strip.empty?

                params_str.split(',').map do |param|
                  # Remove default values: "name = 'default'" => "name"
                  param = param.split('=').first
                  # Remove type annotations: "name:" => "name"
                  param = param.delete(':')
                  # Remove splat and block symbols: "*args", "**kwargs", "&block"
                  param = param.delete('*&')
                  # Strip whitespace
                  param.strip
                end.reject(&:empty?)
              end

              # Fetch parameters via YARD list command (fallback method)
              # @param file [String] file path
              # @param line [Integer] line number
              # @return [Array<String>] array of parameter names
              def fetch_parameters_via_yard(file, line)
                # Query YARD for the method at this location
                # Use Shellwords.escape to prevent command injection
                escaped_file = Shellwords.escape(file)
                query = "'type == :method && file == \"#{escaped_file}\" && line >= #{line - 15} && line <= #{line + 5}'"
                cmd = "yard list --query #{query} 2>/dev/null"

                output = `#{cmd}`.strip
                return [] if output.empty?

                # YARD list doesn't show parameters, we'd need to parse the source
                # So this fallback is just for validation - use source parsing instead
                []
              rescue StandardError => e
                warn "Failed to query YARD: #{e.message}" if ENV['DEBUG']
                []
              end

              # Find the best suggestion using DidYouMean spell checker
              # @param unknown_param [String] the unknown parameter name
              # @param actual_params [Array<String>] array of actual parameter names
              # @return [String, nil] suggested parameter name or nil
              def find_suggestion(unknown_param, actual_params)
                return nil if actual_params.empty?

                # Use DidYouMean::SpellChecker for smart suggestions
                spell_checker = DidYouMean::SpellChecker.new(dictionary: actual_params)
                suggestions = spell_checker.correct(unknown_param)

                # If DidYouMean found suggestions, return the best one
                return suggestions.first unless suggestions.empty?

                # Otherwise, fallback to Levenshtein distance
                find_suggestion_fallback(unknown_param, actual_params)
              rescue StandardError => e
                # Fallback to simple Levenshtein distance if DidYouMean fails
                warn "DidYouMean failed: #{e.message}, using fallback" if ENV['DEBUG']
                find_suggestion_fallback(unknown_param, actual_params)
              end

              # Fallback suggestion finder using simple Levenshtein distance
              # @param unknown_param [String] the unknown parameter name
              # @param actual_params [Array<String>] array of actual parameter names
              # @return [String, nil] suggested parameter name or nil
              def find_suggestion_fallback(unknown_param, actual_params)
                # Calculate Levenshtein distance for each parameter
                distances = actual_params.map do |param|
                  [param, levenshtein_distance(unknown_param, param)]
                end

                # Sort by distance and get the closest match
                best_match = distances.min_by { |_param, distance| distance }

                # Only suggest if the distance is reasonable (less than half the length)
                return nil unless best_match

                param, distance = best_match
                max_distance = [unknown_param.length, param.length].max / 2

                distance <= max_distance ? param : nil
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
