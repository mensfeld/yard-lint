# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # DuplicateNamespaceComment validator
        #
        # Detects namespaces (modules and classes) that carry a YARD documentation
        # comment in more than one file. When a namespace is reopened across several
        # files, YARD merges every reopening into a single object and keeps only one
        # docstring - the last documented reopening wins and all the other comments are
        # silently discarded, with no warning. This is a common accident for shared
        # namespaces (e.g. `Users` or `Users::Operations`) that are spread across many
        # files. It is not a concern for a leaf object such as `Users::Operations::Create`
        # which is normally defined in a single file and can only be documented once.
        #
        # The validator reports one offense per namespace that is documented in two or
        # more files, listing every documented location so the duplicates can be
        # consolidated into a single canonical spot.
        #
        # @example Bad - the same namespace documented in two files
        #   # a.rb
        #   # Handles user operations
        #   module Users; end
        #
        #   # b.rb
        #   # User-related helpers   # &lt;- silently discarded by YARD
        #   module Users; end
        #
        # @example Good - document the namespace in exactly one place
        #   # a.rb
        #   # Handles user operations
        #   module Users; end
        #
        #   # b.rb
        #   module Users; end        # &lt;- reopened without a comment
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Documentation/DuplicateNamespaceComment:
        #       Enabled: false
        module DuplicateNamespaceComment
        end
      end
    end
  end
end
