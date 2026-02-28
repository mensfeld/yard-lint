# frozen_string_literal: true

# ANSI helper class for colorizing output.
class AnsiHelper
  RED = 31

  private_constant :RED

  def red(text)
    colorize(text, RED)
  end

  private

  # Colorize text with ANSI escape codes.
  # @return [String] the colorized text
  # @param text [String] the text to colorize
  # @param color [Symbol] the color to use
  def colorize(text, color)
    "\e[#{color}m#{text}\e[0m"
  end
end
