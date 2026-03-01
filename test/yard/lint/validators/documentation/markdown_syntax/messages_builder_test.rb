# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Documentation::MarkdownSyntax::MessagesBuilder' do
  it 'call formats unclosed backtick error' do
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

  it 'call formats unclosed code block error' do
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

  it 'call formats unclosed bold error' do
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

  it 'call formats invalid list marker error with line number' do
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

  it 'call formats multiple errors' do
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

