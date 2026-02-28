# frozen_string_literal: true

# Example class with both instance and class methods
class ClassMethodsExample
  # Public instance method
  # @param value [String] value to process
  # @return [String] processed value
  def instance_method(value)
    value.upcase
  end

  # Undocumented instance method
  def undocumented_instance(data)
    data.downcase
  end

  # Class method with wrong tag order
  # @return [String] result
  # @param input [String] input data
  def self.class_method_wrong_order(input)
    input.strip
  end

  # Class method with correct documentation
  # @param name [String] the name
  # @return [String] greeting
  def self.class_method_correct(name)
    "Hello, #{name}"
  end

  # Undocumented class method
  def self.undocumented_class_method(value)
    value * 2
  end

  class << self
    # Singleton method with documentation
    # @param text [String] text to reverse
    # @return [String] reversed text
    def singleton_documented(text)
      text.reverse
    end

    # Undocumented singleton method
    def singleton_undocumented(number)
      number + 1
    end

    private

    # Private class method
    # @param data [String] data to process
    # @return [String] processed data
    def private_class_method(data)
      data.upcase
    end
  end
end
