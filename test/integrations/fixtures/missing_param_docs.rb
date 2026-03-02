# frozen_string_literal: true

# Example class with missing parameter documentation
class MissingParamDocs
  # This method is missing param documentation
  # @return [String] result
  def calculate(input, multiplier)
    (input * multiplier).to_s
  end

  # This method has some param docs but not all
  # @param name [String] the name
  # @return [String] greeting
  def greet(name, title)
    "#{title} #{name}"
  end
end
