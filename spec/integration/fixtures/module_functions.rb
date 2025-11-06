# frozen_string_literal: true

# Example module with module_function
module ModuleFunctionsExample
  # This instance/module method has wrong tag order
  # @return [String] result
  # @param data [String] input data
  def process_data(data)
    data.upcase
  end

  # This method has correct documentation
  # @param value [Integer] value to double
  # @return [Integer] doubled value
  def double_value(value)
    value * 2
  end

  # This module function is undocumented
  def undocumented_function(input)
    input.to_s
  end

  module_function :process_data, :double_value, :undocumented_function

  # Regular instance method (not module_function)
  # @param text [String] text to process
  # @return [String] processed text
  def instance_only(text)
    text.strip
  end

  # Undocumented instance method
  def undocumented_instance(value)
    value + 1
  end
end
