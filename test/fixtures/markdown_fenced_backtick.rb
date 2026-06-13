# frozen_string_literal: true

# Demonstrates a fenced code block containing a backtick character.
class MarkdownFencedBacktick
  # Builds a string.
  #
  # ```ruby
  # s = "contains a ` backtick"
  # ```
  #
  # @return [void]
  def build
    nil
  end

  # Has a genuinely unclosed inline backtick.
  # Use `code here without a closing tick.
  # @return [void]
  def unclosed
    nil
  end
end
