# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::ExampleStyle::MessagesBuilder' do
  it 'call builds message with all offense details' do
    offense = {
      object_name: 'User#initialize',
      example_name: 'Basic usage',
      cop_name: 'Style/StringLiterals',
      message: "Prefer single-quoted strings when you don't need interpolation"
    }

    message = Yard::Lint::Validators::Tags::ExampleStyle::MessagesBuilder.call(offense)
    assert_equal(
      "Object `User#initialize` has style offense in @example 'Basic usage': " \
      "Style/StringLiterals: Prefer single-quoted strings when you don't need interpolation",
      message
    )
  end

  it 'call handles different cop names' do
    offense = {
      object_name: 'User#save',
      example_name: 'Saving user',
      cop_name: 'Layout/SpaceInsideParens',
      message: 'Space inside parentheses detected'
    }

    message = Yard::Lint::Validators::Tags::ExampleStyle::MessagesBuilder.call(offense)
    assert_includes(message, 'Layout/SpaceInsideParens')
    assert_includes(message, 'Space inside parentheses detected')
  end

  it 'call handles example names with special characters' do
    offense = {
      object_name: 'User#find',
      example_name: 'Finding user (with options)',
      cop_name: 'Metrics/MethodLength',
      message: 'Method too long'
    }

    message = Yard::Lint::Validators::Tags::ExampleStyle::MessagesBuilder.call(offense)
    assert_includes(message, "'Finding user (with options)'")
  end
end

