# frozen_string_literal: true

# Fixture for testing abstract method detection
class AbstractMethodsExample
  # Abstract method with actual implementation (should be flagged)
  # @abstract Override this method in subclasses
  # @param value [Integer] the value to calculate
  # @return [Integer] the calculated result
  def calculate(value)
    value * 2
  end

  # Properly abstract method (no implementation, should NOT be flagged)
  # @abstract Override this method in subclasses
  # @return [String] the formatted output
  def format
    raise NotImplementedError, 'Subclasses must implement #format'
  end

  # Regular method (not abstract, should NOT be flagged)
  # @param name [String] the name
  # @return [String] greeting
  def greet(name)
    "Hello, #{name}"
  end
end
