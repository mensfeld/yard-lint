# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsForbiddenTagsMessagesBuilderTest < Minitest::Test

  def test_call_formats_message_for_tag_with_specific_types_forbidden
    offense = {
      tag_name: 'return',
      types_text: 'void',
      pattern_types: 'void'
    }

    message = Yard::Lint::Validators::Tags::ForbiddenTags::MessagesBuilder.call(offense)
    assert_equal(
      "Forbidden tag pattern detected: @return [void]. " \
      "Type(s) 'void' are not allowed for @return.",
      message
    )
  end

  def test_call_formats_message_for_tag_only_pattern_no_types
    offense = {
      tag_name: 'api',
      types_text: '',
      pattern_types: ''
    }

    message = Yard::Lint::Validators::Tags::ForbiddenTags::MessagesBuilder.call(offense)

    assert_equal(
      'Forbidden tag detected: @api. ' \
      'This tag is not allowed by project configuration.',
      message
    )
  end

  def test_call_formats_message_with_multiple_types
    offense = {
      tag_name: 'param',
      types_text: 'Object,Hash',
      pattern_types: 'Object,Hash'
    }

    message = Yard::Lint::Validators::Tags::ForbiddenTags::MessagesBuilder.call(offense)

    assert_equal(
      "Forbidden tag pattern detected: @param [Object,Hash]. " \
      "Type(s) 'Object,Hash' are not allowed for @param.",
      message
    )
  end

  def test_call_formats_message_when_types_text_is_nil
    offense = {
      tag_name: 'api',
      types_text: nil,
      pattern_types: nil
    }

    message = Yard::Lint::Validators::Tags::ForbiddenTags::MessagesBuilder.call(offense)

    assert_equal(
      'Forbidden tag detected: @api. ' \
      'This tag is not allowed by project configuration.',
      message
    )
  end
end
