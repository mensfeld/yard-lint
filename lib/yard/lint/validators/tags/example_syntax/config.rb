# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleSyntax
          # Configuration for ExampleSyntax validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :example_syntax
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              # Opt-in: skip @example blocks that are interactive console
              # transcripts (irb/pry sessions, their `=>` output, or shell `$`
              # prompts) rather than runnable Ruby. Off by default so a real
              # syntax error in a normal example is not accidentally hidden.
              'SkipNonRuby' => false
            }.freeze
          end
        end
      end
    end
  end
end
