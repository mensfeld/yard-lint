# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::CollectionType::Result' do
  it 'class attributes has default severity set to convention' do
    assert_equal('convention', Yard::Lint::Validators::Tags::CollectionType::Result.default_severity)
  end

  it 'class attributes has offense type set to style' do
    assert_equal('style', Yard::Lint::Validators::Tags::CollectionType::Result.offense_type)
  end

  it 'class attributes has offense name set to collectiontype' do
    assert_equal('CollectionType', Yard::Lint::Validators::Tags::CollectionType::Result.offense_name)
  end

  it 'build message delegates to messagesbuilder' do
    offense = {
      tag_name: 'param',
      type_string: 'Hash<Symbol, String>'
    }

    Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder
      .stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::CollectionType::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  it 'inheritance inherits from results base' do
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::CollectionType::Result.superclass)
  end
end
