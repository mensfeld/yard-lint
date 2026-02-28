# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsExampleStyleMessagesBuilderTest < Minitest::Test

  def test_call_builds_message_with_all_offense_details
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

  def test_call_handles_different_cop_names
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

  def test_call_handles_example_names_with_special_characters
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
