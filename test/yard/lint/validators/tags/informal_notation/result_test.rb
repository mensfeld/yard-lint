# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::InformalNotation::Result' do
  it 'class attributes has default severity set to warning' do
    assert_equal('warning', Yard::Lint::Validators::Tags::InformalNotation::Result.default_severity)
  end

  it 'class attributes has offense type set to line' do
    assert_equal('line', Yard::Lint::Validators::Tags::InformalNotation::Result.offense_type)
  end

  it 'class attributes has offense name set to informalnotation' do
    assert_equal('InformalNotation', Yard::Lint::Validators::Tags::InformalNotation::Result.offense_name)
  end

  it 'build message delegates to messagesbuilder' do
    offense = {
      pattern: 'Note',
      replacement: '@note',
      line_text: 'Note: This is important'
    }

    Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder.stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::InformalNotation::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  it 'inheritance inherits from results base' do
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::InformalNotation::Result.superclass)
  end
end

