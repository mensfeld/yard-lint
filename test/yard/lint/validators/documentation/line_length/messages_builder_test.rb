# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::LineLength::MessagesBuilder' do
  it 'call formats message with length max_length and object name' do
    offense = {
      length: 135,
      object_name: 'MyClass#process',
      max_length: 120
    }

    message = Yard::Lint::Validators::Documentation::LineLength::MessagesBuilder.call(offense)

    assert_includes(message, '135')
    assert_includes(message, '120')
    assert_includes(message, 'MyClass#process')
  end

  it 'call includes greater-than indicator' do
    offense = { length: 200, object_name: 'Foo#bar', max_length: 100 }
    message = Yard::Lint::Validators::Documentation::LineLength::MessagesBuilder.call(offense)
    assert_includes(message, '200 > 100')
  end

  it 'call works with custom max_length' do
    offense = { length: 85, object_name: 'Foo#bar', max_length: 80 }
    message = Yard::Lint::Validators::Documentation::LineLength::MessagesBuilder.call(offense)
    assert_includes(message, '85 > 80')
  end
end
