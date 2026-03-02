# frozen_string_literal: true

# Comprehensive fixture for testing YARD warnings
class WarningsExample
  # This method has an unknown tag
  # @unknowntag This should trigger UnknownTag warning
  # @param value [String] the value
  # @return [String] result
  def unknown_tag_method(value)
    value
  end

  # This method has a duplicated parameter name
  # @param data [String] first data param
  # @param data [Integer] duplicate data param (should warn)
  # @return [String] result
  def duplicated_param(data)
    data.to_s
  end

  # This method has unknown parameter names in docs
  # @param wrong_name [String] this parameter doesn't exist
  # @param another_wrong [Integer] this also doesn't exist
  # @return [String] result
  def unknown_params(actual_param)
    actual_param.to_s
  end

  # Method with correct documentation for comparison
  # @param correct [String] the correct parameter
  # @return [String] processed value
  def correct_method(correct)
    correct.upcase
  end
end
