# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::MeaninglessTag::MessagesBuilder' do
  it 'call formats message for param on class' do
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

  it 'call formats message for option on module' do
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

  it 'call formats message for param on constant' do
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

