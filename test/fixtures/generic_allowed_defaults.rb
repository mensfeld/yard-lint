# frozen_string_literal: true

# Fixture for testing allowed default types (self, nil, true, false, void)
# inside generic/compound type expressions.
# These are all valid YARD syntax that should NOT be flagged as InvalidTagType.

class GenericAllowedDefaults
  # @return [Array<self>] list of self references
  def array_of_self
    [self]
  end

  # @return [Array<nil>] list of nils
  def array_of_nil
    [nil]
  end

  # @return [Array<true>] list of true values
  def array_of_true
    [true]
  end

  # @return [Array<false>] list of false values
  def array_of_false
    [false]
  end

  # @return [Array<void>] array of void
  def array_of_void
  end

  # @param items [Hash{Symbol => self}] map to self
  # @return [void]
  def hash_value_self(items)
  end

  # @param items [Hash{Symbol => nil}] map to nil
  # @return [void]
  def hash_value_nil(items)
  end

  # @return [Hash{String => true}] map to true
  def hash_value_true
  end

  # @return [Hash{String => false}] map to false
  def hash_value_false
  end

  # @return [Array<Array<self>>] nested generics with self
  def nested_self
    [[self]]
  end

  # @param data [Hash{Symbol => Array<nil>}] deeply nested nil
  # @return [void]
  def deeply_nested_nil(data)
  end
end
