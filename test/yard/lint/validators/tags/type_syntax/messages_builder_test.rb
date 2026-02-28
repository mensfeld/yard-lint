# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTypeSyntaxMessagesBuilderTest < Minitest::Test

  def test_call_formats_type_syntax_violation_message
    offense = {
      tag_name: 'param',
      type_string: 'Array<',
      error_message: "expecting name, got ''"
    }

    message = Yard::Lint::Validators::Tags::TypeSyntax::MessagesBuilder.call(offense)

    assert_equal(
      "Invalid type syntax in @param tag: 'Array<' (expecting name, got '')",
      message
    )
  end

  def test_call_handles_return_tag_violations
    offense = {
      tag_name: 'return',
      type_string: 'Hash{Symbol =>',
      error_message: "expecting name, got ''"
    }

    message = Yard::Lint::Validators::Tags::TypeSyntax::MessagesBuilder.call(offense)

    assert_equal(
      "Invalid type syntax in @return tag: 'Hash{Symbol =>' (expecting name, got '')",
      message
    )
  end

  def test_call_handles_option_tag_violations
    offense = {
      tag_name: 'option',
      type_string: 'Array<>',
      error_message: "expecting name, got '>'"
    }

    message = Yard::Lint::Validators::Tags::TypeSyntax::MessagesBuilder.call(offense)

    assert_equal(
      "Invalid type syntax in @option tag: 'Array<>' (expecting name, got '>')",
      message
    )
  end
end

