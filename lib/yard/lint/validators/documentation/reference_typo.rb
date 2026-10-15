# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # ReferenceTypo validator
        #
        # Detects probable typos in method and constant names referenced from
        # documentation: `{Foo#bar}` links in docstring and tag text, and `@see`
        # targets. A reference is reported only when it does not resolve in the
        # YARD registry, its namespace does, and a close match exists there.
        # References into namespaces YARD does not know (stdlib, other gems) are
        # skipped, as are methods a loaded Ruby ancestor may define. A bare
        # constant is compared only with constants of its enclosing namespaces,
        # not with top-level ones. This validator is enabled by default.
        #
        # @example Bad - link to a misspelled method
        #   # Delegates to {Parser#prase}
        #   def call
        #   end
        #
        # @example Good - link to an existing method
        #   # Delegates to {Parser#parse}
        #   def call
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Documentation/ReferenceTypo:
        #       Enabled: false
        module ReferenceTypo
        end
      end
    end
  end
end
