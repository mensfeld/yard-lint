# frozen_string_literal: true

# Fixture for the TextSubstitution validator integration tests.

# A class whose documentation contains em-dash — characters.
class TextSubstitutionExamples
  # Connects the start — and end of the range.
  # @param start [Integer] start value
  # @param finish [Integer] end value
  # @return [Range]
  def em_dash_method(start, finish)
    start..finish
  end

  # Uses an en-dash – for indicating ranges in prose.
  # @return [String]
  def en_dash_method
    'result'
  end

  # Both em-dash — and en-dash – appear on the same line here.
  # @return [String]
  def both_dashes_method
    'result'
  end

  # Em-dash inside a fenced code block must not trigger.
  #
  # ```ruby
  # # This em-dash — and en-dash – are inside a code fence
  # ```
  #
  # @return [String]
  def with_code_block
    'safe'
  end

  # Uses a plain hyphen - which is perfectly acceptable.
  # @return [String]
  def plain_hyphen_method
    'fine'
  end
end
