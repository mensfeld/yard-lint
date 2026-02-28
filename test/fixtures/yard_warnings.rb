# frozen_string_literal: true

# Class with various YARD warnings
class WarningExamples
  # Method with unknown tag
  # @param name [String] user name
  # @unknowntag this is not a valid YARD tag
  # @return [String] greeting
  def greet(name)
    "Hello #{name}"
  end

  # Method with unknown directive
  # @!unknowndirective
  # @param value [Integer] a value
  # @return [Integer] doubled value
  def double(value)
    value * 2
  end

  # Method with invalid tag format
  # @param name invalid format - missing type
  # @return [String] result
  def process(name)
    name.upcase
  end

  # Method with unknown parameter name in docs
  # @param wrong_name [String] this parameter doesn't exist in method signature
  # @return [Hash] result
  def create(actual_name)
    { name: actual_name }
  end

  # Method with duplicated parameter documentation
  # @param data [String] first documentation
  # @param data [Hash] duplicate documentation for same param
  # @return [Boolean] success
  def save(_data)
    true
  end
end
