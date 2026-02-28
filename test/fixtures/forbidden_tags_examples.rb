# frozen_string_literal: true

# Examples for ForbiddenTags validator testing
# This file contains various tag patterns to test forbidden tag detection

class ForbiddenTagsExamples
  # Method with @return [void] - should be flagged when void is forbidden
  # @return [void]
  def void_return
    puts 'hello'
  end

  # Method with @return [Boolean] - should NOT be flagged
  # @return [Boolean] whether successful
  def boolean_return
    true
  end

  # Method with @return [nil] - should NOT be flagged (alternative to void)
  # @return [nil] always returns nil
  def nil_return
    nil
  end

  # Method with @param [Object] - should be flagged when Object is forbidden
  # @param data [Object] the data
  def object_param(data)
    data.to_s
  end

  # Method with @param [String] - should NOT be flagged
  # @param name [String] the name
  def string_param(name)
    name.upcase
  end

  # Method with multiple types including forbidden one
  # @return [String, void] returns string or nothing
  def mixed_return
    'result'
  end

  # Method with properly documented return
  # @return [String] the formatted result
  def proper_return
    'result'
  end
end

# Class with @api tag - should be flagged when @api is forbidden entirely
# @api private
class ApiPrivateClass
  # Method inside the API private class
  def some_method
    true
  end
end

# Class without @api tag - should NOT be flagged
# Documents the calculator functionality
class CleanClass
  # Adds two numbers
  # @param a [Integer] first number
  # @param b [Integer] second number
  # @return [Integer] the sum
  def add(a, b)
    a + b
  end
end
