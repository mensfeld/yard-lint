# frozen_string_literal: true

# Test fixture for Unicode characters in type specifications
# Contains type specs with non-ASCII characters that should be detected
class UnicodeTypeCharacters
  # Contains Unicode horizontal ellipsis (U+2026) in type specification
  # @param [Symbol, …] flags the flags to use
  # @return [void]
  def unicode_ellipsis(*flags)
    flags
  end

  # Contains Unicode right arrow (U+2192) in type specification
  # @param value [Integer→String] value with arrow
  # @return [void]
  def unicode_arrow(value)
    value
  end

  # Contains Unicode em dash (U+2014) in type specification
  # @param [String—Integer] range value with em dash
  # @return [void]
  def unicode_em_dash(range)
    range
  end

  # Valid ASCII type specification for comparison
  # @param [String, Symbol, nil] value normal type spec
  # @return [Boolean] result
  def valid_ascii_types(value)
    !value.nil?
  end
end
