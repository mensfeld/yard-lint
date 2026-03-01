# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::TagTypePosition::Result' do
  it 'has default severity set to convention' do
    assert_equal('convention', Yard::Lint::Validators::Tags::TagTypePosition::Result.default_severity)
  end

  it 'has offense type set to style' do
    assert_equal('style', Yard::Lint::Validators::Tags::TagTypePosition::Result.offense_type)
  end

  it 'has offense name set to tagtypeposition' do
    assert_equal('TagTypePosition', Yard::Lint::Validators::Tags::TagTypePosition::Result.offense_name)
  end

  it 'build message delegates to messagesbuilder' do
    offense = {
      tag_name: 'param',
      param_name: 'name',
      type_info: 'String',
      detected_style: 'type_after_name'
    }

    Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder
      .expects(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::TagTypePosition::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  it 'inherits from results base' do
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::TagTypePosition::Result.superclass)
  end
end
