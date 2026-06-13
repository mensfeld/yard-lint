# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedObjects
          # Class used to extract details about undocumented objects from raw yard list output
          # @example
          #   /path/to/file.rb:3: UndocumentedClass
          #   /path/to/file.rb:4: UndocumentedClass#method_one|2
          class Parser < ::Yard::Lint::Parsers::Base
            # Regex used to parse yard list output format
            # Format: file.rb:LINE: ObjectName or ObjectName|ARITY
            LINE_REGEX = /^(.+):(\d+): (.+?)(?:\|(\d+))?$/

            # @param yard_list_output [String] raw yard list results string
            # @param config [Yard::Lint::Config, nil] configuration object (optional)
            # @option _kwargs [Object] :unused this parameter accepts no options (reserved for future use)
            # @return [Array<Hash>] Array with undocumented objects details
            def call(yard_list_output, config: nil, **_kwargs)
              excluded_methods = config&.validator_config(
                'Documentation/UndocumentedObjects',
                'ExcludedMethods'
              ) || []

              # Ensure excluded_methods is an Array
              excluded_methods = Array(excluded_methods)

              # Sanitize patterns: remove nil, empty, whitespace-only, and normalize
              excluded_methods = sanitize_patterns(excluded_methods)

              yard_list_output
                .split("\n")
                .map(&:strip)
                .reject(&:empty?)
                .filter_map do |line|
                  match = line.match(LINE_REGEX)
                  next unless match

                  element = match[3]
                  arity = match[4]&.to_i

                  # Skip if method is in excluded list
                  next if method_excluded?(element, arity, excluded_methods)

                  {
                    location: match[1],
                    line: match[2].to_i,
                    element: element
                  }
                end
            end

            private

            # Checks if a method should be excluded based on ExcludedMethods config
            # Supports: simple names, arity notation, and regex patterns
            # @param element [String] the element name (e.g., "Class#method")
            # @param arity [Integer, nil] number of parameters (required + optional,
            #   excluding splat and block)
            # @param excluded_methods [Array<String>] list of exclusion patterns
            # @return [Boolean] true if method should be excluded
            def method_excluded?(element, arity, excluded_methods)
              # Extract method name from element (e.g., "Foo::Bar#baz" -> "baz")
              method_name = element.split(/[#.]/).last
              return false unless method_name

              excluded_methods.any? do |pattern|
                case pattern
                when %r{^/(.+)/$}
                  # Regex pattern: '/^_/' matches methods starting with _
                  match_regex_pattern(method_name, Regexp.last_match(1))
                when %r{/\d+$}
                  # Arity pattern: 'initialize/0' checks method name and parameter count
                  match_arity_pattern(method_name, arity, pattern)
                else
                  # Simple name match: 'initialize'
                  # Simple names match any arity (use arity notation for specific arity)
                  method_name == pattern
                end
              end
            end

            # Sanitize exclusion patterns
            # @param patterns [Array] raw patterns from config
            # @return [Array<String>] cleaned and validated patterns
            def sanitize_patterns(patterns)
              patterns
                .compact # Remove nil values
                .map { |p| p.to_s.strip } # Convert to strings and trim whitespace
                .reject(&:empty?) # Remove empty strings
                .reject { |p| p == '//' } # Reject empty regex (matches everything)
            end

            # Match a regex pattern against method name with error handling
            # @param method_name [String] the method name to match
            # @param regex_pattern [String] the regex pattern (without delimiters)
            # @return [Boolean] true if matches, false if invalid regex or no match
            def match_regex_pattern(method_name, regex_pattern)
              return false if regex_pattern.empty? # Empty regex would match everything

              Regexp.new(regex_pattern).match?(method_name)
            rescue RegexpError
              # Invalid regex - skip this pattern
              false
            end

            # Match an arity pattern like "initialize/0"
            # @param method_name [String] the method name
            # @param arity [Integer, nil] number of parameters the method accepts (nil if unknown)
            # @param pattern [String] the full pattern like "initialize/0"
            # @return [Boolean] true if matches
            def match_arity_pattern(method_name, arity, pattern)
              pattern_name, pattern_arity_str = pattern.split('/')

              # Validate arity is numeric
              return false unless pattern_arity_str.match?(/^\d+$/)

              pattern_arity = pattern_arity_str.to_i

              method_name == pattern_name && arity == pattern_arity
            end
          end
        end
      end
    end
  end
end
