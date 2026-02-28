# frozen_string_literal: true

# Example class with mixed visibility levels in one file
class MixedVisibilityExample
  # Public method with documentation
  # @param value [String] value to process
  # @return [String] processed value
  def public_documented(value)
    value.upcase
  end

  # Public method without documentation
  def public_undocumented(data)
    data.downcase
  end

  # Public method with wrong tag order
  # @return [Integer] result
  # @param number [Integer] input number
  def public_wrong_order(number)
    number * 2
  end

  protected

  # Protected method with documentation
  # @param text [String] text to process
  # @return [String] result
  def protected_documented(text)
    text.strip
  end

  # Protected method without documentation
  def protected_undocumented(input)
    input.reverse
  end

  # Protected method with wrong tag order
  # @return [Boolean] result
  # @param flag [Boolean] input flag
  def protected_wrong_order(flag)
    !flag
  end

  private

  # Private method with documentation
  # @param item [String] item to check
  # @return [Boolean] validation result
  def private_documented(item)
    !item.empty?
  end

  # Private method without documentation
  def private_undocumented(value)
    value + 1
  end

  # Private method with wrong tag order
  # @return [Array] result
  # @param list [Array] input list
  def private_wrong_order(list)
    list.sort
  end
end
