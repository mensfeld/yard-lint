# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # ExampleStyle validator
        #
        # Validates code style in `@example` tags using RuboCop or StandardRB.
        # This validator ensures that code examples follow the same style guidelines
        # as the project codebase for consistency.
        #
        # ## Requirements
        #
        # - RuboCop or StandardRB gem must be installed
        # - Validator auto-detects which linter to use based on project setup
        #
        # ## Configuration
        #
        # Basic usage:
        #
        #     Tags/ExampleStyle:
        #       Enabled: true
        #
        # Advanced configuration:
        #
        #     Tags/ExampleStyle:
        #       Enabled: true
        #       Linter: auto  # 'auto', 'rubocop', 'standard', or 'none'
        #       SkipPatterns:
        #         - '/skip-lint/i'
        #         - '/bad code/i'
        #       DisabledCops:
        #         - 'Metrics/MethodLength'
        #
        # ## Skipping Examples
        #
        # Skip linting for specific examples (negative examples):
        #
        #     # @example Bad code (skip-lint)
        #     #   user = User.new("invalid")
        #
        # Or use inline RuboCop directives:
        #
        #     # @example
        #     #   # rubocop:disable all
        #     #   user = User.new("invalid")
        #     #   # rubocop:enable all
        module ExampleStyle
          autoload :Validator, 'yard/lint/validators/tags/example_style/validator'
          autoload :Config, 'yard/lint/validators/tags/example_style/config'
          autoload :Parser, 'yard/lint/validators/tags/example_style/parser'
          autoload :Result, 'yard/lint/validators/tags/example_style/result'
          autoload :MessagesBuilder, 'yard/lint/validators/tags/example_style/messages_builder'
          autoload :LinterDetector, 'yard/lint/validators/tags/example_style/linter_detector'
          autoload :RubocopRunner, 'yard/lint/validators/tags/example_style/rubocop_runner'
        end
      end
    end
  end
end
