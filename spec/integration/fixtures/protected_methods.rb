# frozen_string_literal: true

# Example class with protected methods
class ProtectedMethodsExample
  # Public method with documentation
  # @param value [String] the value
  # @return [String] processed value
  def public_method(value)
    protected_helper(value)
  end

  protected

  # This protected method has docs with wrong tag order (should trigger Tags/Order)
  # @return [String] result
  # @param data [String] input data
  def protected_wrong_order(data)
    data.upcase
  end

  # This protected method has correct documentation
  # @param input [String] input data
  # @return [String] result
  def protected_correct(input)
    input.downcase
  end

  # This protected method is undocumented (should NOT trigger documentation validators if excluded)
  def undocumented_protected(value)
    value * 2
  end

  def another_undocumented_protected
    'test'
  end

  protected

  # Protected helper method
  # @param text [String] text to process
  # @return [String] processed text
  def protected_helper(text)
    text.strip
  end
end
