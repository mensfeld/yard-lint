# frozen_string_literal: true

# Fixture file for testing the Tags/Order validator
# Contains various tag ordering scenarios

# Class with correct tag ordering
class CorrectTagOrder
  # Method with all tags in correct order
  # @param value [Integer] input value
  # @option value [String] :name optional name
  # @yield [result] yields the result
  # @yieldparam result [String] the yielded result
  # @yieldreturn [Boolean] whether to continue
  # @return [String] the output
  # @raise [ArgumentError] if value is invalid
  # @see OtherClass#method
  # @example Basic usage
  #   correct_full_order(42)
  # @note This is an important note
  # @todo Optimize this method
  def correct_full_order(value)
    yield value.to_s
  end

  # Method with subset of tags in correct order
  # @param data [Hash] input data
  # @return [Boolean] success status
  # @note Remember to validate input
  def correct_partial_order(_data)
    true
  end

  # Method with only param and return (most common case)
  # @param name [String] the name
  # @return [String] greeting
  def simple_correct_order(name)
    "Hello, #{name}"
  end
end

# Class with invalid tag ordering
class InvalidTagOrderExamples
  # Wrong: @return before @param
  # @return [String] result
  # @param value [Integer] input value
  def return_before_param(value)
    value.to_s
  end

  # Wrong: @note before @return
  # @param value [Integer] input value
  # @note This note is misplaced
  # @return [String] result
  def note_before_return(value)
    value.to_s
  end

  # Wrong: @note before @example
  # @param value [Integer] input value
  # @return [String] result
  # @note This note should come after example
  # @example Usage
  #   example_after_note(1)
  def note_before_example(value)
    value.to_s
  end

  # Wrong: @see before @return
  # @param value [Integer] input value
  # @see OtherClass
  # @return [String] result
  def see_before_return(value)
    value.to_s
  end

  # Wrong: @todo before @note
  # @param value [Integer] input value
  # @return [String] result
  # @todo Should come after note
  # @note This note should come first
  def todo_before_note(value)
    value.to_s
  end

  # Wrong: @yield tags out of order
  # @param block [Proc] the block
  # @yieldreturn [Boolean] the return
  # @yield [value] yields value
  # @yieldparam value [String] the value
  # @return [void]
  def yield_tags_wrong_order
    yield 'test'
  end

  # Wrong: @raise before @return
  # @param value [Integer] input
  # @raise [ArgumentError] on error
  # @return [Boolean] success
  def raise_before_return(value)
    raise ArgumentError if value.negative?

    true
  end
end

# Class to test multiple consecutive same tags (should NOT trigger violations)
class ConsecutiveSameTags
  # Multiple @param tags in sequence - correct
  # @param first [String] first param
  # @param second [Integer] second param
  # @param third [Boolean] third param
  # @return [Array] all params
  def multiple_params(first, second, third)
    [first, second, third]
  end

  # Multiple @note tags in sequence - correct
  # @param value [Integer] the value
  # @return [String] result
  # @note First note
  # @note Second note
  # @note Third note
  def multiple_notes(value)
    value.to_s
  end

  # Multiple @example tags in sequence - correct
  # @param value [Integer] the value
  # @return [Integer] doubled value
  # @example With positive
  #   multiple_examples(5) #=> 10
  # @example With negative
  #   multiple_examples(-3) #=> -6
  def multiple_examples(value)
    value * 2
  end
end
