# frozen_string_literal: true

# Fixture for testing @api tag detection
class ApiTagsExample
  # Public method without @api tag
  # @param name [String] the name
  # @return [String] greeting
  def greet(name)
    "Hello, #{name}"
  end

  # Method with @api tag
  # @api public
  # @param value [Integer] the value
  # @return [Integer] doubled value
  def double(value)
    value * 2
  end

  # Another method without @api tag
  # @param items [Array] the items
  # @return [Integer] count
  def count(items)
    items.size
  end
end
