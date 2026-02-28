# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationMarkdownSyntaxMessagesBuilderTest < Minitest::Test

  def test_call_formats_unclosed_backtick_error
    offense = {
      object_name: 'MyClass#process',
      errors: ['unclosed_backtick']
    }

    message = Yard::Lint::Validators::Documentation::MarkdownSyntax::MessagesBuilder.call(offense)

    assert_equal(
      "Markdown syntax errors in 'MyClass#process': " \
      'Unclosed backtick in documentation',
      message
    )
  end

  def test_call_formats_unclosed_code_block_error
    offense = {
      object_name: 'MyClass#execute',
      errors: ['unclosed_code_block']
    }

    message = Yard::Lint::Validators::Documentation::MarkdownSyntax::MessagesBuilder.call(offense)

    assert_equal(
      "Markdown syntax errors in 'MyClass#execute': " \
      'Unclosed code block (```) in documentation',
      message
    )
  end

  def test_call_formats_unclosed_bold_error
    offense = {
      object_name: 'MyClass#configure',
      errors: ['unclosed_bold']
    }

    message = Yard::Lint::Validators::Documentation::MarkdownSyntax::MessagesBuilder.call(offense)

    assert_equal(
      "Markdown syntax errors in 'MyClass#configure': " \
      'Unclosed bold formatting (**) in documentation',
      message
    )
  end

  def test_call_formats_invalid_list_marker_error_with_line_number
    offense = {
      object_name: 'MyClass#setup',
      errors: ['invalid_list_marker:3']
    }

    message = Yard::Lint::Validators::Documentation::MarkdownSyntax::MessagesBuilder.call(offense)

    assert_equal(
      "Markdown syntax errors in 'MyClass#setup': " \
      'Invalid list marker (use - or * instead) at line 3',
      message
    )
  end

  def test_call_formats_multiple_errors
    offense = {
      object_name: 'MyClass#process',
      errors: %w[unclosed_backtick unclosed_bold]
    }

    message = Yard::Lint::Validators::Documentation::MarkdownSyntax::MessagesBuilder.call(offense)

    assert_equal(
      "Markdown syntax errors in 'MyClass#process': " \
      'Unclosed backtick in documentation, ' \
      'Unclosed bold formatting (**) in documentation',
      message
    )
  end
end

