# frozen_string_literal: true

require 'did_you_mean'

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

                # Parse directly from the Ruby source file.
                parse_parameters_from_source(file, line_num)
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

                # The warning is reported at the method's def line, so start
                # there - scanning earlier would pick up an unrelated method
                # defined in the preceding lines.
                start_line = [line, 1].max
                end_line = line + 5

                # Only read the lines in the relevant range to avoid loading the whole file
                lines = []
                current_line_num = 1
                File.foreach(file) do |source_line|
                  lines << source_line if current_line_num.between?(start_line, end_line)
                  break if current_line_num > end_line

                  current_line_num += 1
                end

                # Search for method definition in the collected lines
                in_multiline_def = false
                param_lines = []

                lines.each do |source_line|
                  # The method name may include a receiver (def self.foo, def
                  # obj.foo) or be an operator, so match anything up to the
                  # opening parenthesis rather than a bare \w+.
                  # Match single-line method definitions: def method_name(param1, param2)
                  if source_line =~ /^\s*def\s+[^(]+\((.*?)\)/
                    params_str = ::Regexp.last_match(1)
                    return extract_parameter_names(params_str)
                  # Match start of multi-line method definition: def method_name(
                  elsif source_line =~ /^\s*def\s+[^(]+\((.*)$/
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
                  elsif source_line.match?(/^\s*def\s+[^(]+$/)
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

                split_top_level_params(params_str).filter_map do |param|
                  # Strip leading splat/block markers (*args, **kwargs, &block).
                  name = param.strip.sub(/\A[*&]+/, '')
                  # The name is everything up to the first ':' (keyword) or '='
                  # (default), so a symbol default like `mode: :fast` or a default
                  # containing commas like `list = [1, 2]` is not mangled.
                  name = name[/\A[^:=]+/].to_s.strip
                  name.empty? ? nil : name
                end
              end

              # Splits a parameter string on top-level commas, respecting
              # brackets so defaults like `[1, 2]` or `{a: 1}` stay intact.
              # @param params_str [String] the raw parameter list
              # @return [Array<String>] individual parameter substrings
              def split_top_level_params(params_str)
                parts = []
                current = +''
                depth = 0
                params_str.each_char do |char|
                  case char
                  when '(', '[', '{' then depth += 1; current << char
                  when ')', ']', '}' then depth -= 1; current << char
                  when ','
                    if depth.zero?
                      parts << current
                      current = +''
                    else
                      current << char
                    end
                  else
                    current << char
                  end
                end
                parts << current
                parts
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
                # Require the edit distance to be strictly less than half the
                # longer length, so short, very different names are not
                # "corrected" to an unrelated parameter.
                max_length = [unknown_param.length, param.length].max

                distance < max_length / 2.0 ? param : nil
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
