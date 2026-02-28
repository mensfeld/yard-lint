# frozen_string_literal: true

# Test fixture for TagTypePosition validator

# Valid: type after parameter name (YARD standard)
class ValidTypePosition
  # Process user data
  # @param name [String] user name
  # @param age [Integer] user age
  # @return [Boolean] success
  def process(name, age)
    true
  end
end

# Invalid: type before parameter name (violates YARD standard)
class InvalidTypePosition
  # Process user data
  # @param [String] name user name
  # @param [Integer] age user age
  # @return [Boolean] success
  def process(name, age)
    true
  end
end

# Mixed: some correct, some incorrect
class MixedTypePosition
  # Process data
  # @param name [String] user name (correct - YARD standard)
  # @param [Hash] opts options (incorrect - type before name)
  # @return [Symbol] status code
  def process(name, opts)
    :ok
  end
end
