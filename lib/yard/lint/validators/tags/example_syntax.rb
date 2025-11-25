# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Tags validators - validate YARD tag quality and consistency
      module Tags
        # ExampleSyntax validator
        #
        # Validates Ruby syntax in `@example` tags using RubyVM::InstructionSequence.compile().
        # This validator ensures that code examples in documentation are syntactically valid.
        # It automatically strips output indicators (`#=>`) and skips incomplete single-line
        # snippets. This validator is enabled by default.
        #
        # @example Bad - Invalid Ruby syntax in example
        #   # @example
        #   #   def broken(
        #   #     # missing closing
        #   def my_method
        #   end
        #
        # @example Good - Valid Ruby syntax in example
        #   # @example
        #   #   def my_method(name)
        #   #     puts name
        #   #   end
        #   def my_method(name)
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Tags/ExampleSyntax:
        #       Enabled: false
        module ExampleSyntax
        end
      end
    end
  end
end
