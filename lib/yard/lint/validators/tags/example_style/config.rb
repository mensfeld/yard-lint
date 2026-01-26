# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleStyle
          # Configuration for ExampleStyle validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :example_style
            self.defaults = {
              'Enabled' => false,  # Opt-in validator
              'Severity' => 'convention',
              'Linter' => 'auto',  # 'auto', 'rubocop', 'standard', or 'none'
              'SkipPatterns' => [],
              'DisabledCops' => [
                # File-level cops that don't make sense for code snippets
                'Style/FrozenStringLiteralComment',
                'Layout/TrailingWhitespace',
                'Layout/EndOfLine',
                'Layout/TrailingEmptyLines',
                'Metrics/MethodLength',
                'Metrics/AbcSize',
                'Metrics/CyclomaticComplexity',
                'Metrics/PerceivedComplexity'
              ]
            }.freeze
          end
        end
      end
    end
  end
end
