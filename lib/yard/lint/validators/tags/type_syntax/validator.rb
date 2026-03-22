# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TypeSyntax
          # Runs YARD to validate type syntax using TypesExplainer::Parser
          class Validator < Base
            # Matches valid Ruby symbol literals: :foo, :foo?, :foo!, :foo=, :"foo bar"
            SYMBOL_LITERAL = /\A:[a-zA-Z_]\w*[?!=]?\z/
            # Matches valid quoted symbol literals: :"foo", :'foo'
            QUOTED_SYMBOL_LITERAL = /\A:["'][^"']*["']\z/
            # Matches string literals: "foo", 'foo'
            STRING_LITERAL = /\A(["'])[^"']*\1\z/

            private_constant :SYMBOL_LITERAL, :QUOTED_SYMBOL_LITERAL, :STRING_LITERAL

            # Enable in-process execution
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Validates type syntax in tags using YARD's TypesExplainer::Parser.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              validated_tags = config.validator_config('Tags/TypeSyntax', 'ValidatedTags') ||
                               %w[param option return yieldreturn]

              object.docstring.tags
                    .select { |tag| validated_tags.include?(tag.tag_name) }
                    .each do |tag|
                next unless tag.types

                tag.types.each do |type_str|
                  # Skip literal types that YARD accepts but TypesExplainer::Parser doesn't
                  # See: https://github.com/mensfeld/yard-lint/issues/109
                  next if type_str.match?(SYMBOL_LITERAL)
                  next if type_str.match?(QUOTED_SYMBOL_LITERAL)
                  next if type_str.match?(STRING_LITERAL)

                  begin
                    YARD::Tags::TypesExplainer::Parser.parse(type_str)
                  rescue SyntaxError => e
                    # Sanitize error message to handle invalid UTF-8 sequences
                    # YARD's parser may generate malformed error messages for non-ASCII input
                    error_msg = e.message.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
                    collector.puts "#{object.file}:#{object.line}: #{object.title}"
                    collector.puts "#{tag.tag_name}|#{type_str}|#{error_msg}"
                    break
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
