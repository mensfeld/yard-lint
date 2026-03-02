# frozen_string_literal: true

require 'test_helper'

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
end

