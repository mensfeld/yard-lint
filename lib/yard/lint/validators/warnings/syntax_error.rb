# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Validators for checking YARD warnings
      module Warnings
        # SyntaxError validator
        #
        # Flags Ruby files that YARD could not parse because of a syntax error.
        # Such files are silently skipped by YARD - they contribute no objects and
        # therefore no documentation offenses - so without this validator a run
        # could pass (exit 0) over code that does not even parse. This validator
        # surfaces the parser error as an offense (severity `error` by default),
        # making the run exit non-zero. Enabled by default.
        #
        # For example, a file whose method signature is missing its closing
        # parenthesis (`def foo(x` followed by a body and `end`) fails to parse;
        # YARD reports `Syntax error in <file>:(LINE,COL): ...` and this validator
        # turns that into an offense. A file that parses cleanly produces nothing.
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Warnings/SyntaxError:
        #       Enabled: false
        #
        module SyntaxError
        end
      end
    end
  end
end
