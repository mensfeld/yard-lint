# frozen_string_literal: true

# Groups the user-facing operations for the demo namespace.
module DuplicateNs
  # A leaf class documented in exactly one file, so it is never flagged.
  class Leaf
    # @return [Symbol] the leaf marker
    def name
      :leaf
    end
  end
end
