# frozen_string_literal: true

# Test fixture for EmptyCommentLine validator

# Valid: No empty lines at start or end
# This is a properly documented class
class ValidClass
  # Valid: Description with no empty lines
  # @param value [String] the value
  # @return [Boolean] success
  def valid_method(value)
    true
  end

  # Valid: Empty line BETWEEN sections (allowed)
  # This method has a description.
  #
  # @param foo [String] the foo
  #
  # @return [String] result
  def valid_with_spacing(foo)
    foo
  end
end

#
# Invalid: Leading empty line before class doc
class LeadingEmptyClass
end

# Invalid: Trailing empty line after class doc
#
class TrailingEmptyClass
end

#
# Invalid: Both leading and trailing
#
class BothEmptyClass
end

module TestModule
  #
  # Invalid: Leading empty in method doc
  def leading_method; end

  # Invalid: Trailing empty in method doc
  #
  def trailing_method; end

  # Valid: Just a regular method
  # @return [nil]
  def valid_method; end
end

# Constants
#
# Invalid: Leading on constant doc
CONST_LEADING = 1

# Valid constant doc
VALID_CONST = 2

# Multiple empty lines at start
#
#
# Description
def multiple_leading; end

# Description
#
#
def multiple_trailing; end

# Whitespace variations
#
# Description (prev line has trailing spaces - should be flagged)
def whitespace_test; end
