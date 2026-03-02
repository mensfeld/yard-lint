# frozen_string_literal: true

# Test fixture for CollectionType validator

# Valid: Hash with correct YARD syntax
class ValidHashSyntax
  # Process configuration options
  # @param opts [Hash{Symbol => String}] configuration hash
  # @return [Boolean] success status
  def process(opts)
    true
  end
end

# Valid: Array with generic syntax (allowed in YARD)
class ValidArraySyntax
  # Process items
  # @param items [Array<String>] list of items
  # @return [Integer] count
  def process(items)
    items.size
  end
end

# Invalid: Hash with generic syntax
class InvalidHashSyntax
  # Process configuration options
  # @param opts [Hash<Symbol, String>] configuration hash
  # @return [Boolean] success status
  def process(opts)
    true
  end
end

# Invalid: Nested Hash with generic syntax
class InvalidNestedHash
  # Process complex data
  # @param data [Hash<String, Hash<Symbol, Integer>>] nested data
  # @return [Hash] processed data
  def process(data)
    data
  end
end

# Invalid: Multiple params with mixed syntax
class MixedSyntax
  # Process data with options
  # @param items [Array<String>] list of items (valid)
  # @param opts [Hash<Symbol, String>] options (invalid)
  # @return [Hash{Symbol => Array<String>}] grouped results (valid)
  def process(items, opts)
    {}
  end
end

# Valid: Complex nested types
class ComplexValidTypes
  # Process complex structure
  # @param data [Hash{String => Array<Hash{Symbol => Integer}>}] complex structure
  # @return [Boolean] success
  def process(data)
    true
  end
end

# Invalid: Return type with Hash<>
class InvalidReturnType
  # Get configuration
  # @return [Hash<String, Object>] configuration hash
  def config
    {}
  end
end
