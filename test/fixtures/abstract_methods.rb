# frozen_string_literal: true

# Base class with abstract methods
class AbstractBase
  # Abstract method that should be implemented by subclasses
  # @abstract Subclasses must implement this method
  # @param data [Hash] input data
  # @return [Hash] processed data
  def process(data)
    raise NotImplementedError, 'Subclasses must implement process method'
  end

  # Abstract method with actual implementation (violation)
  # @abstract Subclasses should override this
  # @param value [Integer] input value
  # @return [Integer] result
  def calculate(value)
    value * 2
  end

  # Regular method without @abstract tag (correct)
  # @param name [String] name
  # @return [String] greeting
  def greet(name)
    "Hello #{name}"
  end
end
