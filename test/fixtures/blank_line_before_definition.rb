# frozen_string_literal: true

# Fixture file for BlankLineBeforeDefinition validator tests.
# Contains methods with various blank line scenarios between documentation and definitions.
class BlankLineBeforeDefinitionExamples
  # Valid: No blank lines between documentation and definition
  # @param value [String] the value to process
  # @return [String] processed value
  def valid_no_blank_lines(value)
    value.to_s
  end

  # Single blank line: YARD still associates docs but violates conventions
  # @param data [Hash] the data to transform
  # @return [Hash] transformed data

  def single_blank_line(data)
    data.transform_keys(&:to_s)
  end

  # Two blank lines: Documentation is orphaned - YARD ignores it
  # @param items [Array] the items to filter
  # @return [Array] filtered items


  def two_blank_lines(items)
    items.compact
  end

  # Three blank lines: Documentation is orphaned - YARD ignores it
  # @param count [Integer] the count
  # @return [Integer] doubled count



  def three_blank_lines(count)
    count * 2
  end

  # Valid: Another method with no blank lines
  # @param name [String] the name
  # @return [Symbol] symbolized name
  def another_valid_method(name)
    name.to_sym
  end

  # Single blank line before public method (renamed for clarity)
  # @param secret [String] the secret value
  # @return [String] encoded secret

  def method_with_single_blank(secret)
    secret.reverse
  end

  protected

  # Valid protected method - no blank lines
  # @param data [String] the data
  # @return [String] processed data
  def protected_valid_method(data)
    data.upcase
  end

  # Protected method with single blank line
  # @param value [Integer] the value
  # @return [Integer] doubled value

  def protected_single_blank(value)
    value * 2
  end

  # Protected method with orphaned documentation
  # @param name [String] the name
  # @return [Symbol] symbolized name


  def protected_orphaned_docs(name)
    name.to_sym
  end

  private

  # Valid private method - no blank lines
  # @param item [Object] the item
  # @return [String] string representation
  def private_valid_method(item)
    item.to_s
  end

  # Private method with single blank line
  # @param count [Integer] the count
  # @return [Integer] tripled count

  def private_single_blank(count)
    count * 3
  end

  # Private method with orphaned documentation
  # @param flag [Boolean] the flag
  # @return [Boolean] inverted flag


  def private_orphaned_docs(flag)
    !flag
  end
end

# Valid class with no blank line
# @example Usage
#   MyValidClass.new
class MyValidClass
end

# Class with single blank line
# @example Usage
#   MySingleBlankClass.new

class MySingleBlankClass
end

# Class with orphaned documentation (2 blank lines)
# @example Usage
#   MyOrphanedClass.new


class MyOrphanedClass
end

# Module with no blank lines
# @example Usage
#   MyValidModule.call
module MyValidModule
end

# Module with single blank line
# @example Usage
#   MySingleBlankModule.call

module MySingleBlankModule
end

# Module with orphaned documentation (2 blank lines)
# @example Usage
#   MyOrphanedModule.call


module MyOrphanedModule
end
