# frozen_string_literal: true

# Fixture for yield-detection tests: "yield" used as a symbol hash key or
# keyword-argument label is not a block yield.
class YieldLabelMethods
  # Builds the feature flags hash
  # @return [Hash] feature flags
  def build_flags
    { yield: true, other: false }
  end

  # Configures the runner
  # @return [void]
  def configure
    apply(yield: 1)
  end

  # Iterates over stored items
  # @param items [Array] the items
  # @return [void]
  def each_item(items)
    items.each { |item| yield item }
  end

  private

  # Applies the given options
  # @param options [Hash] options to apply
  # @return [void]
  def apply(**options)
    options
  end
end
