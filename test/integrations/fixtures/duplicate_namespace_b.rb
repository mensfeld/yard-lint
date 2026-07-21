# frozen_string_literal: true

# Adds shared helpers to the demo namespace in a second file.
module DuplicateNs
  # Another leaf, also defined in exactly one file.
  class Other
    # @return [Symbol] the other marker
    def name
      :other
    end
  end
end
