# frozen_string_literal: true

# Test fixture for @example syntax validation
module ExampleSyntaxFixtures
  # Method with valid example
  # @example Valid code
  #   result = add(2, 3)
  #   puts result #=> 5
  # @param first [Integer] first number
  # @param second [Integer] second number
  # @return [Integer] sum
  def self.add(first, second)
    first + second
  end

  # Method with syntax error in example
  # @example Invalid syntax
  #   result = subtract(5 2)  # Missing comma - syntax error
  #   puts result
  # @param first [Integer] first number
  # @param second [Integer] second number
  # @return [Integer] difference
  def self.subtract(first, second)
    first - second
  end

  # Method with incomplete snippet (should be skipped)
  # @example Usage
  #   multiply(3, 4)
  # @param first [Integer] first number
  # @param second [Integer] second number
  # @return [Integer] product
  def self.multiply(first, second)
    first * second
  end

  # Method with complete valid block
  # @example Complete example
  #   def process
  #     x = 10
  #     y = 20
  #     x + y
  #   end
  # @return [void]
  def self.process
    # implementation
  end

  # Method with syntax error in block
  # @example Broken block
  #   def broken
  #     if x == 1
  #       puts "one"
  #     # Missing end for if
  #   end
  # @return [void]
  def self.broken_example
    # implementation
  end

  # Method with output indicators (should be cleaned)
  # @example With output
  #   [1, 2, 3].map { |x| x * 2 } #=> [2, 4, 6]
  #   "hello".upcase #=> "HELLO"
  # @return [void]
  def self.with_output
    # implementation
  end
end
