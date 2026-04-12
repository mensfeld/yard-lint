# frozen_string_literal: true

# Fixture for testing type validation on @raise tags.

class RaiseTagTypes
  # Valid @raise types - should not be flagged
  # @param value [String] input value
  # @return [String] the result
  # @raise [ArgumentError] if value is invalid
  # @raise [TypeError] if wrong type
  def valid_raise(value)
    value
  end

  # Invalid @raise type syntax - should be flagged by TypeSyntax
  # @param value [String] input value
  # @return [String] the result
  # @raise [Array<>] empty generic is invalid syntax
  def invalid_raise_syntax(value)
    value
  end
end
