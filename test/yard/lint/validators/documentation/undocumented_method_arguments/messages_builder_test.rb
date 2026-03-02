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
end

