# frozen_string_literal: true

# Methods with literal and non-literal type specifications.
class NonAsciiStringLiteral
  # Uses string-literal types that legitimately contain non-ASCII.
  # @param mode ["naïve", "plain"] the processing mode
  # @return [void]
  def process(mode)
    mode
  end

  # Uses a real type name with a non-ASCII character (invalid).
  # @param value [Strïng] the value
  # @return [void]
  def store(value)
    value
  end
end
