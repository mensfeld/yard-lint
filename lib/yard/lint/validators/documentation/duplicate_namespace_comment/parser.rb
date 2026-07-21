# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module DuplicateNamespaceComment
          # Extracts duplicate namespace documentation offenses from raw collector output.
          # Each line has the form "file:line: Namespace\tsite|site|...\tconflict" where
          # conflict is either 'same' or 'differ'.
          # @example Output format (skip-lint)
          #   /a.rb:6: Foo::Bar\t/a.rb:6|/b.rb:6\tsame
          class Parser < ::Yard::Lint::Parsers::Base
            # Parses the "file:line: Namespace" head of an offense line. The namespace
            # path uses '::' and never ': ', so the final ": " is an unambiguous separator.
            LINE_REGEX = /\A(.+):(\d+): (.+)\z/

            # @param output [String] raw collector output, one offense per line
            # @return [Array<Hash>] offense hashes with location/line/namespace/sites/conflict
            def call(output)
              return [] if output.nil? || output.empty?

              output.split("\n").filter_map do |line|
                head, sites, conflict = line.split("\t")
                next unless head

                match = head.match(LINE_REGEX)
                next unless match

                {
                  location: match[1],
                  line: match[2].to_i,
                  namespace: match[3],
                  sites: (sites || '').split('|'),
                  conflict: conflict
                }
              end
            end
          end
        end
      end
    end
  end
end
