# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UndocumentedObjects
          # Class used to extract details about undocumented objects from raw yard list output
          # @example Output format (skip-lint)
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

              excluded_objects = config&.validator_config(
                'Documentation/UndocumentedObjects',
                'ExcludedObjects'
              ) || []

              # Ensure patterns are Arrays and sanitize: remove nil, empty,
              # whitespace-only, and normalize
              excluded_methods = sanitize_patterns(Array(excluded_methods))
              excluded_objects = sanitize_patterns(Array(excluded_objects))

              yard_list_output
                .split("\n")
                .map(&:strip)
                .reject(&:empty?)
                .filter_map do |line|
                  match = line.match(LINE_REGEX)
                  next unless match

                  element = match[3]
                  arity = match[4]&.to_i

                  # Skip if the fully-qualified object name is excluded. Unlike
                  # ExcludedMethods (which matches only the trailing method name
                  # and never applies to classes/modules/constants),
                  # ExcludedObjects matches the whole element - so it can
                  # exclude constants (e.g. "Foo::KEY_A") and lets a regex be
                  # anchored to the full path.
                  next if object_excluded?(element, arity, excluded_objects)

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
              # ExcludedMethods only applies to methods. A class, module, or
              # constant element has no #/. separator, so never derive a
              # "method name" from it - otherwise a pattern like /cache/ would
              # silently suppress the offense for a class such as Memcached.
              return false unless element.match?(/[#.]/)

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

            # Checks if an object should be excluded based on ExcludedObjects config.
            # Matches against the fully-qualified object name (the whole element),
            # so it applies to every object type - classes, modules, methods, and
            # constants alike. Supports exact full names, arity notation (for
            # methods), and regex patterns matched against the full path.
            # @param element [String] the fully-qualified object name
            #   (e.g. "Foo::Bar#baz", "Foo::Bar", "Foo::KEY_A")
            # @param arity [Integer, nil] number of parameters for a method element
            #   (required + optional, excluding splat and block); nil for
            #   classes, modules, and constants
            # @param excluded_objects [Array<String>] list of exclusion patterns
            # @return [Boolean] true if the object should be excluded
            def object_excluded?(element, arity, excluded_objects)
              excluded_objects.any? do |pattern|
                case pattern
                when %r{^/(.+)/$}
                  # Regex pattern matched against the full path: '/^Foo::KEY_/'
                  match_regex_pattern(element, Regexp.last_match(1))
                when %r{/\d+$}
                  # Arity pattern on a full path: 'Foo::Bar#baz/1' matches the
                  # method Foo::Bar#baz only when it takes exactly one parameter.
                  # A full path contains a single '/' (the arity delimiter), so
                  # match_arity_pattern splits it correctly. Constants and other
                  # objects have a nil arity and never match an arity pattern.
                  match_arity_pattern(element, arity, pattern)
                else
                  # Exact full-name match: 'Foo::Bar::KEY_A'
                  element == pattern
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
