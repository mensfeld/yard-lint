# frozen_string_literal: true

# Fixture for testing type validation on @yieldparam tags.

class YieldparamTypes
  # Valid @yieldparam types - should not be flagged
  # @yieldparam item [String] the yielded item
  # @yieldparam index [Integer] the index
  # @yieldreturn [void]
  # @return [void]
  def each_with_index(&block)
    block&.call('item', 0)
  end

  # Invalid @yieldparam type syntax - should be flagged by TypeSyntax
  # @yieldparam item [Array<>] empty generic is invalid syntax
  # @yieldreturn [void]
  # @return [void]
  def each_invalid(&block)
    block&.call('item')
  end
end
