# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::MeaninglessTag::Result' do
  it 'class attributes has default severity set to warning' do
    assert_equal('warning', Yard::Lint::Validators::Tags::MeaninglessTag::Result.default_severity)
  end

  it 'class attributes has offense type set to class' do
    assert_equal('class', Yard::Lint::Validators::Tags::MeaninglessTag::Result.offense_type)
  end

  it 'class attributes has offense name set to meaninglesstag' do
    assert_equal('MeaninglessTag', Yard::Lint::Validators::Tags::MeaninglessTag::Result.offense_name)
  end

  it 'build message delegates to messagesbuilder' do
    offense = {
      object_type: 'class',
      tag_name: 'param',
      object_name: 'InvalidClass'
    }

    Yard::Lint::Validators::Tags::MeaninglessTag::MessagesBuilder
      .stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::MeaninglessTag::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  it 'inheritance inherits from results base' do
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::MeaninglessTag::Result.superclass)
  end
end

