# frozen_string_literal: true

# Fixture for ExampleSyntax output-marker tests.
class ExampleOutputMarker
  # Prints a message that itself contains a "# =>" sequence in a string literal.
  #
  # @example
  #   msg = "result # => not actually output"
  #   puts msg
  # @return [void]
  def announce
    nil
  end

  # Demonstrates a real output marker after a valid expression.
  #
  # @example
  #   1 + 1 # => 2
  # @return [void]
  def add
    nil
  end

  # A genuinely broken example.
  #
  # @example
  #   def broken
  #     x = (1 +
  #   end
  # @return [void]
  def really_broken
    nil
  end
end
