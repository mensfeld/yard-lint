# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsInformalNotationMessagesBuilderTest < Minitest::Test

  def test_call_formats_message_for_note_pattern
    offense = {
      pattern: 'Note',
      replacement: '@note',
      line_text: 'Note: This is important'
    }

    message = Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder.call(offense)

    assert_equal(
      "Use @note tag instead of 'Note:' notation. Found: \"Note: This is important\"",
      message
    )
  end

  def test_call_formats_message_for_todo_pattern
    offense = {
      pattern: 'TODO',
      replacement: '@todo',
      line_text: 'TODO: Fix this later'
    }

    message = Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder.call(offense)

    assert_equal(
      "Use @todo tag instead of 'TODO:' notation. Found: \"TODO: Fix this later\"",
      message
    )
  end

  def test_call_formats_message_for_deprecated_pattern
    offense = {
      pattern: 'Deprecated',
      replacement: '@deprecated',
      line_text: 'Deprecated: Use new_method instead'
    }

    message = Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder.call(offense)

    assert_equal(
      "Use @deprecated tag instead of 'Deprecated:' notation. " \
      'Found: "Deprecated: Use new_method instead"',
      message
    )
  end

  def test_call_handles_empty_line_text
    offense = {
      pattern: 'Note',
      replacement: '@note',
      line_text: ''
    }

    message = Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder.call(offense)

    assert_equal("Use @note tag instead of 'Note:' notation", message)
  end

  def test_call_handles_nil_line_text
    offense = {
      pattern: 'Note',
      replacement: '@note',
      line_text: nil
    }

    message = Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder.call(offense)

    assert_equal("Use @note tag instead of 'Note:' notation", message)
  end
  def test_call_truncates_long_line_text
    long_text = 'Note: ' + ('x' * 100)
    offense = {
      pattern: 'Note',
      replacement: '@note',
      line_text: long_text
    }

    message = Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder.call(offense)

    assert_includes(message, '...')
    assert_operator(message.length, :<, (long_text.length + 50))
  end
end

