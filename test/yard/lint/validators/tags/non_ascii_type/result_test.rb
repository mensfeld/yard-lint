# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::NonAsciiType::Result' do
  it 'class attributes has default severity set to warning' do
    assert_equal('warning', Yard::Lint::Validators::Tags::NonAsciiType::Result.default_severity)
  end

  it 'class attributes has offense type set to method' do
    assert_equal('method', Yard::Lint::Validators::Tags::NonAsciiType::Result.offense_type)
  end

  it 'class attributes has offense name set to nonasciitype' do
    assert_equal('NonAsciiType', Yard::Lint::Validators::Tags::NonAsciiType::Result.offense_name)
  end

  it 'build message delegates to messagesbuilder' do
    offense = {
      tag_name: 'param',
      type_string: 'Symbol, …',
      character: '…',
      codepoint: 'U+2026'
    }

    Yard::Lint::Validators::Tags::NonAsciiType::MessagesBuilder
      .stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::NonAsciiType::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  it 'inheritance inherits from results base' do
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::NonAsciiType::Result.superclass)
  end
end
