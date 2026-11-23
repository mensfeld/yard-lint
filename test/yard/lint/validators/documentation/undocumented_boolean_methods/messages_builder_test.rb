# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::MessagesBuilder' do
  it 'call names the missing return tag of the method' do
    offense = { element: 'Checker#enabled?' }

    message = Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::MessagesBuilder.call(offense)

    assert_equal('The `Checker#enabled?` method has no @return tag', message)
  end

  it 'call names the missing return tag of a root method' do
    offense = { element: '::enabled?' }

    message = Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::MessagesBuilder.call(offense)

    assert_equal('The `::enabled?` method has no @return tag', message)
  end
end
