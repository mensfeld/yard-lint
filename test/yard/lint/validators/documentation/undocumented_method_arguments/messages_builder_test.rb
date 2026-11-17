# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UndocumentedMethodArguments::MessagesBuilder' do
  it 'call builds message for undocumented method arguments' do
    offense = { method_name: 'calculate' }

    message = Yard::Lint::Validators::Documentation::UndocumentedMethodArguments::MessagesBuilder.call(offense)

    assert_equal(
      'The `calculate` method is missing documentation for some of the arguments.',
      message
    )
  end

  it 'call builds message for instance method' do
    offense = { method_name: 'MyClass#process' }

    message = Yard::Lint::Validators::Documentation::UndocumentedMethodArguments::MessagesBuilder.call(offense)

    assert_equal(
      'The `MyClass#process` method is missing documentation for some of the arguments.',
      message
    )
  end

  it 'call keeps the generic message when no missing names are known' do
    offense = { method_name: 'calculate', missing_params: [] }

    message = Yard::Lint::Validators::Documentation::UndocumentedMethodArguments::MessagesBuilder.call(offense)

    assert_equal(
      'The `calculate` method is missing documentation for some of the arguments.',
      message
    )
  end

  it 'call names a single missing argument' do
    offense = { method_name: 'greet', missing_params: %w[name] }

    message = Yard::Lint::Validators::Documentation::UndocumentedMethodArguments::MessagesBuilder.call(offense)

    assert_equal('The `greet` method has no @param for: name', message)
  end

  it 'call names every missing argument' do
    offense = { method_name: 'undocumented', missing_params: %w[a b] }

    message = Yard::Lint::Validators::Documentation::UndocumentedMethodArguments::MessagesBuilder.call(offense)

    assert_equal('The `undocumented` method has no @param for: a, b', message)
  end
end
