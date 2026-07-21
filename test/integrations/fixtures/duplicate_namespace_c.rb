# frozen_string_literal: true

module DuplicateNs
  # A leaf added without re-documenting the namespace itself.
  class Third
    # @return [Symbol] the third marker
    def name
      :third
    end
  end
end
