# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::ForbiddenTags::MessagesBuilder' do
  it 'call formats message for tag with specific types forbidden' do
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

  it 'call formats message for tag only pattern no types' do
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

  it 'call formats message with multiple types' do
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

  it 'call formats message when types text is nil' do
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

