# frozen_string_literal: true

# Fixture for TagGroupSeparator example-body tests.
class TagGroupSeparatorExample
  # Computes and stores a result
  #
  # @example Usage
  #   compute
  #   @result = compute
  #
  # @return [void]
  def perform
    @result = nil
  end

  # Joins two values with no separator between tag groups
  # @param foo [String] the foo
  # @return [String] the joined value
  def joined(foo)
    foo
  end
end
