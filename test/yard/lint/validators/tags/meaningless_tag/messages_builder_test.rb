# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsMeaninglessTagMessagesBuilderTest < Minitest::Test

  def test_call_formats_message_for_param_on_class
    offense = {
      object_type: 'class',
      tag_name: 'param',
      object_name: 'InvalidClass'
    }

    message = Yard::Lint::Validators::Tags::MeaninglessTag::MessagesBuilder.call(offense)

    assert_equal(
      'The @param tag is meaningless on a class (InvalidClass). ' \
      'This tag only makes sense on methods.',
      message
    )
  end

  def test_call_formats_message_for_option_on_module
    offense = {
      object_type: 'module',
      tag_name: 'option',
      object_name: 'InvalidModule'
    }

    message = Yard::Lint::Validators::Tags::MeaninglessTag::MessagesBuilder.call(offense)

    assert_equal(
      'The @option tag is meaningless on a module (InvalidModule). ' \
      'This tag only makes sense on methods.',
      message
    )
  end

  def test_call_formats_message_for_param_on_constant
    offense = {
      object_type: 'constant',
      tag_name: 'param',
      object_name: 'INVALID_CONSTANT'
    }

    message = Yard::Lint::Validators::Tags::MeaninglessTag::MessagesBuilder.call(offense)

    assert_equal(
      'The @param tag is meaningless on a constant (INVALID_CONSTANT). ' \
      'This tag only makes sense on methods.',
      message
    )
  end
end

