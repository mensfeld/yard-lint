# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # UndocumentedObjects validator
        #
        # Checks for missing documentation on classes, modules, and methods.
        # This validator supports flexible method exclusions through the `ExcludedMethods`
        # configuration option.
        #
        # ## Pattern Types
        #
        # The `ExcludedMethods` feature supports three pattern types for maximum flexibility:
        #
        # ### 1. Exact Name Matching
        #
        # Excludes methods with the specified name, regardless of arity:
        #
        #     ExcludedMethods:
        #       - 'to_s'           # Excludes ALL to_s methods regardless of parameters
        #       - 'inspect'        # Excludes ALL inspect methods
        #
        # Note: Exact name matching excludes the method with **any arity**. If you need
        # arity-specific exclusions, use arity notation instead.
        #
        # ### 2. Arity Notation (method_name/N)
        #
        # Excludes methods with specific parameter counts:
        #
        #     ExcludedMethods:
        #       - 'initialize/0'   # Only excludes initialize with NO parameters (default)
        #       - 'call/1'         # Only excludes call methods with exactly 1 parameter
        #       - 'initialize/2'   # Only excludes initialize with exactly 2 parameters
        #
        # Note: Arity counts total parameters (required + optional) excluding splat (*)
        # and block (&) parameters.
        #
        # ### 3. Regex Patterns
        #
        # Excludes methods matching a regular expression:
        #
        #     ExcludedMethods:
        #       - '/^_/'           # Excludes all methods starting with underscore (private convention)
        #       - '/^test_/'       # Excludes all test methods
        #       - '/_(helper|util)$/' # Excludes methods ending with _helper or _util
        #
        # ## Configuration Examples
        #
        # ### Minimal setup - Only exclude parameter-less initialize
        #
        #     Documentation/UndocumentedObjects:
        #       ExcludedMethods:
        #         - 'initialize/0'
        #
        # ### Common Rails/Ruby patterns
        #
        #     Documentation/UndocumentedObjects:
        #       ExcludedMethods:
        #         - 'initialize/0'       # Parameter-less constructors
        #         - '/^_/'               # Private methods (by convention)
        #         - 'to_s'               # String conversion
        #         - 'inspect'            # Object inspection
        #         - 'hash'               # Hash code generation
        #         - 'eql?'               # Equality comparison
        #         - '=='                 # Binary equality operator
        #         - '<=>'                # Spaceship operator (comparison)
        #         - '+'                  # Addition operator
        #         - '-'                  # Subtraction operator
        #         - '+@'                 # Unary plus operator
        #         - '-@'                 # Unary minus operator
        #
        # ### Test framework exclusions
        #
        #     Documentation/UndocumentedObjects:
        #       ExcludedMethods:
        #         - '/^test_/'           # Minitest methods
        #         - '/^should_/'         # Shoulda methods
        #         - 'setup/0'            # Setup with no params
        #         - 'teardown/0'         # Teardown with no params
        #
        # ## Pattern Validation & Edge Cases
        #
        # The `ExcludedMethods` feature includes robust validation and error handling:
        #
        # **Automatic Pattern Sanitization:**
        # - **Nil values** are automatically removed
        # - **Empty strings** and whitespace-only patterns are filtered out
        # - **Whitespace trimming** is applied to all patterns
        # - **Empty regex patterns** (`//`) are rejected (would match everything)
        # - **Non-array values** are automatically converted to arrays
        #
        # **Invalid Pattern Handling:**
        # - **Invalid regex patterns** (e.g., `/[/`, `/(unclosed`) are silently skipped without crashing
        # - **Invalid arity notation** (e.g., `method/abc`, `method/`) is silently skipped
        # - **Pattern matching is case-sensitive** for both exact names and regex
        #
        # **Operator Method Support:**
        # YARD-Lint fully supports Ruby operator methods including:
        # - Binary operators: `+`, `-`, `*`, `/`, `%`, `**`, `==`, `!=`, `===`, `<`, `>`,
        #   `<=`, `>=`, `<=>`, `&`, `|`, `^`, `<<`, `>>`
        # - Unary operators: `+@`, `-@`, `!`, `~`
        # - Other special methods: `[]`, `[]=`, `=~`
        #
        # **Pattern Matching Behavior:**
        # - **Any match excludes**: If a method matches any pattern, it is excluded from validation
        # - **Patterns are evaluated in order** as defined in the configuration
        # - **Exact names have no arity restriction**: `'initialize'` excludes all initialize
        #   methods, regardless of parameters
        # - **Arity notation is strict**: `'initialize/0'` only excludes initialize with
        #   exactly 0 parameters
        #
        # ## Troubleshooting
        #
        # ### Methods still showing as undocumented
        #
        # 1. Verify the method name matches exactly (case-sensitive)
        # 2. Check if you're using arity notation - ensure the arity count is correct
        # 3. For regex patterns, test your regex independently to ensure it matches
        # 4. Remember: Arity counts `required + optional` parameters, **excluding**
        #    splat (`*args`) and block (`&block`)
        #
        # ### Regex patterns not working
        #
        # 1. Ensure you're using `/pattern/` format with forward slashes
        # 2. Test the regex in Ruby: `Regexp.new('your_pattern').match?('method_name')`
        # 3. Escape special regex characters: `\.`, `\(`, `\)`, `\[`, `\]`, etc.
        # 4. Invalid regex patterns are silently skipped - check for syntax errors
        #
        # ### Arity not matching
        #
        # 1. Count parameters correctly: `def method(a, b = 1)` has arity 2 (required + optional)
        # 2. Splat parameters don't count: `def method(a, *rest)` has arity 1
        # 3. Block parameters don't count: `def method(a, &block)` has arity 1
        # 4. Keyword arguments count as individual parameters: `def method(a:, b:)` has arity 2
        #
        module UndocumentedObjects
        end
      end
    end
  end
end
