# frozen_string_literal: true

# Fixture for block/splat parameter documentation tests. Blocks are
# documented with @yield rather than @param, and splat/double-splat params
# follow the same arity convention the rest of the gem uses (excluded from
# the count).
class BlockAndSplatParams
  # Iterates over the items, yielding each one
  # @param limit [Integer] maximum number of items
  # @yield [item] each item in turn
  # @return [void]
  def each_limited(limit, &block)
    limit.times { |item| block.call(item) }
  end

  # Collects the given values
  # @return [Array] the collected values
  def collect(*values)
    values
  end

  # Forwards keyword options
  # @return [void]
  def forward(**options)
    options
  end

  # Genuinely undocumented positional argument
  # @return [void]
  def needs_docs(name, count)
    [name, count]
  end
end
