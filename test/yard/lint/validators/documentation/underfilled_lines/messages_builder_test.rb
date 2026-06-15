# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UnderfilledLines::MessagesBuilder' do
  it 'call formats message with line counts, widest fill and object name' do
    offense = {
      actual_lines: 3,
      reflowed_lines: 2,
      widest_fill: 57,
      max_length: 120,
      object_name: 'MyClass#process'
    }

    message = Yard::Lint::Validators::Documentation::UnderfilledLines::MessagesBuilder.call(offense)

    assert_includes(message, '3 lines')
    assert_includes(message, 'fits in 2')
    assert_includes(message, '57/120')
    assert_includes(message, 'MyClass#process')
  end

  it 'call references the configured max length' do
    offense = {
      actual_lines: 2,
      reflowed_lines: 1,
      widest_fill: 40,
      max_length: 100,
      object_name: 'Foo#bar'
    }

    message = Yard::Lint::Validators::Documentation::UnderfilledLines::MessagesBuilder.call(offense)
    assert_includes(message, '<=100 cols')
    assert_includes(message, '40/100')
  end
end
