# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Semantic::AbstractMethods::MessagesBuilder' do
  it 'call builds message for abstract method with implementation' do
    offense = { method_name: 'MyClass#abstract_method' }

    message = Yard::Lint::Validators::Semantic::AbstractMethods::MessagesBuilder.call(offense)

    assert_equal(
      'Abstract method `MyClass#abstract_method` has implementation ' \
      '(should only raise NotImplementedError or be empty)',
      message
    )
  end

  it 'call builds message for class method' do
    offense = { method_name: 'MyModule.abstract_factory' }

    message = Yard::Lint::Validators::Semantic::AbstractMethods::MessagesBuilder.call(offense)

    assert_equal(
      'Abstract method `MyModule.abstract_factory` has implementation ' \
      '(should only raise NotImplementedError or be empty)',
      message
    )
  end
end

