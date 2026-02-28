# frozen_string_literal: true

# Example class with private methods
class PrivateMethodsExample
  # Public method with documentation
  # @param value [String] the value
  # @return [String] processed value
  def public_method(value)
    internal_process(value)
  end

  private

  # This private method has docs with wrong tag order (should trigger Tags/Order)
  # @return [String] result
  # @param data [String] input data
  def documented_private_wrong_order(data)
    data.upcase
  end

  # This private method has correct documentation
  # @param input [String] input data
  # @return [String] result
  def documented_private_correct(input)
    input.downcase
  end

  # This private method is undocumented (should NOT trigger documentation validators)
  def undocumented_private(value)
    value * 2
  end

  def another_undocumented_private
    'test'
  end
end
