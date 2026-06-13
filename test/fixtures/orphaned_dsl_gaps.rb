# frozen_string_literal: true

# Exercises DSL patterns YARD documents but the validator wrongly flagged.
class OrphanedDslGaps
  # Memoized value.
  # @return [Integer] the value
  memoize def value
    42
  end

  # Registered via a receiver DSL call.
  # @return [void]
  MyDSL.register :thing do
    nil
  end

  # @method dynamic_size
  # A dynamically-defined accessor.
  # @return [Integer] the current count
  acts_as_counter do
    nil
  end

  # A genuinely orphaned comment with a tag.
  # @param foo [String] the foo
  x = 1
end
