# frozen_string_literal: true

# Fixture for testing invalid tag type detection
class InvalidTagTypesExample
  # Method with an invalid type in @param tag
  # @param value [UndefinedType] an undefined type
  # @return [String] the result
  def process_value(value)
    value.to_s
  end

  # Method with invalid generic type
  # @param items [Array<NonExistentClass>] collection of items
  # @return [Integer] count
  def count_items(items)
    items.size
  end
end
