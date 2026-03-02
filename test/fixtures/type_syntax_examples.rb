# frozen_string_literal: true

# Test fixture for type syntax validation
# Contains both valid and invalid type syntax examples
class TypeSyntaxExamples
  # Valid: properly closed brackets
  # @param data [Array<String>] input data
  # @return [Hash{Symbol => String}] result
  def valid_types(data)
    data.each_with_object({}) { |item, hash| hash[item.to_sym] = item }
  end

  # Invalid: closing bracket without opener
  # @param items [Array<] items list]
  # @return [Array] processed items
  def unclosed_bracket(items)
    items
  end

  # Invalid: empty generic
  # @param value [String] input value
  # @return [Array<>] empty array
  def empty_generic(_value)
    []
  end

  # Invalid: closing brace without completion
  # @param key [Symbol] hash key
  # @return [Hash{Symbol =>] incomplete hash type]
  def unclosed_hash(key)
    { key => 'value' }
  end

  # Invalid: missing closing brace in hash
  # @param data [String] data
  # @return [Hash{Symbol] should be Hash{Symbol => Type}
  def malformed_hash(data)
    { data: data }
  end

  # Valid: multiple types (union)
  # @param value [String, Integer, nil] mixed type value
  # @return [Boolean] success status
  def multiple_types(value)
    !value.nil?
  end

  # Valid: nested generics
  # @param matrix [Array<Array<Integer>>] 2D array
  # @return [Integer] sum of all values
  def nested_generics(matrix)
    matrix.flatten.sum
  end

  # Invalid: unclosed nested bracket
  # @param data [Array<Hash{Symbol =>] nested type error
  # @return [void]
  def nested_unclosed(data)
    # implementation
  end
end
