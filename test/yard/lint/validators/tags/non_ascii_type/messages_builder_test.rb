# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsNonAsciiTypeMessagesBuilderTest < Minitest::Test

  def test_call_formats_non_ascii_type_violation_message_with_ellipsis
    offense = {
      tag_name: 'param',
      type_string: 'Symbol, …',
      character: '…',
      codepoint: 'U+2026'
    }

    message = Yard::Lint::Validators::Tags::NonAsciiType::MessagesBuilder.call(offense)

    assert_equal(
      "Type specification in @param tag contains non-ASCII character '…' (U+2026) " \
      "in 'Symbol, …'. Ruby type names must use ASCII characters only.",
      message
    )
  end

  def test_call_formats_non_ascii_type_violation_message_with_arrow
    offense = {
      tag_name: 'return',
      type_string: 'String→Integer',
      character: '→',
      codepoint: 'U+2192'
    }

    message = Yard::Lint::Validators::Tags::NonAsciiType::MessagesBuilder.call(offense)

    assert_equal(
      "Type specification in @return tag contains non-ASCII character '→' (U+2192) " \
      "in 'String→Integer'. Ruby type names must use ASCII characters only.",
      message
    )
  end

  def test_call_formats_non_ascii_type_violation_message_with_em_dash
    offense = {
      tag_name: 'option',
      type_string: 'String—Integer',
      character: '—',
      codepoint: 'U+2014'
    }

    message = Yard::Lint::Validators::Tags::NonAsciiType::MessagesBuilder.call(offense)

    assert_equal(
      "Type specification in @option tag contains non-ASCII character '—' (U+2014) " \
      "in 'String—Integer'. Ruby type names must use ASCII characters only.",
      message
    )
  end

  def test_call_handles_yieldreturn_tag_violations
    offense = {
      tag_name: 'yieldreturn',
      type_string: 'Résult',
      character: 'é',
      codepoint: 'U+00E9'
    }

    message = Yard::Lint::Validators::Tags::NonAsciiType::MessagesBuilder.call(offense)

    assert_includes(message, '@yieldreturn tag')
    assert_includes(message, "'é'")
    assert_includes(message, 'U+00E9')
  end
end
