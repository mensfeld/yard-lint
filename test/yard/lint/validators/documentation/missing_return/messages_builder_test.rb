# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder' do
  it 'call builds message for instance method' do
    offense = { element: 'Calculator#add' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert_equal('Missing @return tag for `Calculator#add`', message)
  end

  it 'call builds message for class method' do
    offense = { element: 'Calculator.new' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert_equal('Missing @return tag for `Calculator.new`', message)
  end

  it 'call builds message for namespaced class instance method' do
    offense = { element: 'Foo::Bar::Baz#method' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert_equal('Missing @return tag for `Foo::Bar::Baz#method`', message)
  end

  it 'call builds message for method with special characters' do
    offense = { element: 'Example#valid?' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert_equal('Missing @return tag for `Example#valid?`', message)
  end

  it 'call includes element name in backticks' do
    offense = { element: 'MyClass#my_method' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert_includes(message, '`MyClass#my_method`')
  end

  it 'call starts with missing return tag for' do
    offense = { element: 'AnyClass#any_method' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert(message.start_with?('Missing @return tag for'))
  end
end

