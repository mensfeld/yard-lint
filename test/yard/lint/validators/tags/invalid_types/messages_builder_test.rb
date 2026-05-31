# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::InvalidTypes::MessagesBuilder' do
  it 'call builds message for invalid tag types' do
    offense = { method_name: 'calculate' }

    message = Yard::Lint::Validators::Tags::InvalidTypes::MessagesBuilder.call(offense)

    assert_equal('The `calculate` has at least one tag with an invalid type definition.', message)
  end

  it 'call builds message for class method' do
    offense = { method_name: 'MyClass.validate' }

    message = Yard::Lint::Validators::Tags::InvalidTypes::MessagesBuilder.call(offense)

    assert_equal('The `MyClass.validate` has at least one tag with an invalid type definition.', message)
  end

  it 'call includes invalid type names when tag violations present' do
    offense = {
      method_name: 'call',
      tag_violations: [
        { tag: '@return', param: nil, types: ['SomeUndefinedClass'] }
      ]
    }

    message = Yard::Lint::Validators::Tags::InvalidTypes::MessagesBuilder.call(offense)

    assert_includes(message, '`call`')
    assert_includes(message, 'invalid type(s)')
    assert_includes(message, '@return')
    assert_includes(message, '`SomeUndefinedClass`')
  end

  it 'call includes param name when violation has one' do
    offense = {
      method_name: 'process',
      tag_violations: [
        { tag: '@param', param: 'body', types: ['anything'] }
      ]
    }

    message = Yard::Lint::Validators::Tags::InvalidTypes::MessagesBuilder.call(offense)

    assert_includes(message, '@param body')
    assert_includes(message, '`anything`')
  end

  it 'call lists multiple violations separated by semicolon' do
    offense = {
      method_name: 'call',
      tag_violations: [
        { tag: '@param', param: 'body', types: ['TypeA'] },
        { tag: '@return', param: nil, types: ['TypeB'] }
      ]
    }

    message = Yard::Lint::Validators::Tags::InvalidTypes::MessagesBuilder.call(offense)

    assert_includes(message, '@param body')
    assert_includes(message, '@return')
    assert_match(/TypeA.*TypeB|TypeB.*TypeA/, message)
  end
end
