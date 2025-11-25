# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # MarkdownSyntax validator
        #
        # Validates markdown syntax in documentation comments. This validator checks
        # for common markdown errors and formatting issues in YARD documentation
        # strings. This validator is enabled by default.
        #
        # @example Bad - Invalid markdown syntax
        #   # This is [broken markdown
        #   # Another line with `unclosed code
        #   def process
        #   end
        #
        # @example Good - Valid markdown syntax
        #   # This is [valid markdown](https://example.com)
        #   # Another line with `closed code`
        #   def process
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Documentation/MarkdownSyntax:
        #       Enabled: false
        module MarkdownSyntax
        end
      end
    end
  end
end
