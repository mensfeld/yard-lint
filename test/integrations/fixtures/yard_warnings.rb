# frozen_string_literal: true

# Fixture for testing YARD parser warnings
class YardWarningsExample
  # Method with unknown tag
  # @unknowntag this should trigger a warning
  # @param value [String] the value
  # @return [String] result
  def process(value)
    value.upcase
  end

  # Method with malformed tag
  # @param [String] missing parameter name
  # @return [String] result
  def transform(input)
    input.downcase
  end

  # Method with duplicate tags
  # @param value [String] first description
  # @param value [Integer] second description (duplicate)
  # @return [String] result
  def convert(value)
    value.to_s
  end
end
