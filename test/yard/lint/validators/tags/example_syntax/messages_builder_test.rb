# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::ExampleSyntax::MessagesBuilder' do
  it 'call builds message for syntax error in example' do
    offense = {
      object_name: 'MyClass#method',
      example_name: 'Basic usage',
      error_message: 'syntax error, unexpected end-of-input'
    }

    message = Yard::Lint::Validators::Tags::ExampleSyntax::MessagesBuilder.call(offense)

    assert_equal(
      "Object `MyClass#method` has syntax error in @example 'Basic usage': " \
      'syntax error, unexpected end-of-input',
      message
    )
  end

  it 'call builds message with numbered example name' do
    offense = {
      object_name: 'Calculator#add',
      example_name: 'Example 2',
      error_message: 'syntax error, unexpected tIDENTIFIER'
    }

    message = Yard::Lint::Validators::Tags::ExampleSyntax::MessagesBuilder.call(offense)

    assert_equal(
      "Object `Calculator#add` has syntax error in @example 'Example 2': " \
      'syntax error, unexpected tIDENTIFIER',
      message
    )
  end
end

