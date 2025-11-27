# frozen_string_literal: true

# Fixture file for testing the InformalNotation validator
# Contains various informal notation patterns that should be flagged

# Note: This class has informal notation
class InformalNoteClass
  # Note: This method has a note
  # @param value [String] the value
  # @return [String]
  def with_note(value)
    value
  end

  # TODO: This needs to be implemented
  # @return [Boolean]
  def with_todo
    false
  end

  # See: https://example.com for more info
  # @return [String]
  def with_see
    'result'
  end

  # Warning: This is deprecated
  # @return [nil]
  def with_warning
    nil
  end

  # Deprecated: Use new_method instead
  # @return [nil]
  def with_deprecated
    nil
  end

  # This method has proper YARD tags
  # @note This is a proper note tag
  # @todo This is a proper todo tag
  # @return [String]
  def with_proper_tags
    'proper'
  end

  # This has code block that should not trigger
  # ```ruby
  # Note: This is inside a code block
  # TODO: This should not be flagged
  # ```
  # @return [String]
  def with_code_block
    'code'
  end

  # FIXME: This is a fixme that should use @todo
  # @return [Boolean]
  def with_fixme
    true
  end
end
