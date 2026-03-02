# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::TypeSyntax::MessagesBuilder' do
  it 'call formats type syntax violation message' do
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

  it 'call handles return tag violations' do
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

  it 'call handles option tag violations' do
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

