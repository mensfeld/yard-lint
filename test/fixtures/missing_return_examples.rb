# frozen_string_literal: true

# Examples for testing the MissingReturn validator
class MissingReturnExamples
  # Bad: Missing @return tag
  def method_without_return
    42
  end

  # Good: Has @return tag
  # @return [Integer] the answer
  def method_with_return
    42
  end

  # Should be excluded by default (initialize methods)
  def initialize
    @value = 0
  end

  # Should be excluded with regex '/^_/' pattern
  def _private_method
    :private
  end

  # Boolean method without an explicit @return tag in source.
  # YARD auto-populates @return for `?` methods, so MissingReturn will not flag this.
  def enabled?
    true
  end

  # Method with parameters missing @return
  # @param name [String] the name
  def greet(name)
    "Hello, #{name}"
  end

  # Method with full documentation including @return
  # @param x [Integer] first number
  # @param y [Integer] second number
  # @return [Integer] the sum of x and y
  def add(x, y)
    x + y
  end

  # Method with no parameters and no @return tag
  def current_time
    Time.now
  end

  # Method with @return [void] should not have return value
  # @return [void]
  def do_something
    puts 'doing something'
  end
end
