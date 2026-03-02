# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder' do
  it 'call formats message for note pattern' do
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

  it 'call formats message for todo pattern' do
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

  it 'call formats message for deprecated pattern' do
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

  it 'call handles empty line text' do
    offense = {
      pattern: 'Note',
      replacement: '@note',
      line_text: ''
    }

    message = Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder.call(offense)

    assert_equal("Use @note tag instead of 'Note:' notation", message)
  end

  it 'call handles nil line text' do
    offense = {
      pattern: 'Note',
      replacement: '@note',
      line_text: nil
    }

    message = Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder.call(offense)

    assert_equal("Use @note tag instead of 'Note:' notation", message)
  end
  it 'call truncates long line text' do
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

