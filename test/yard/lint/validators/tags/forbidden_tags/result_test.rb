# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::ForbiddenTags::Result' do
  it 'class attributes has default severity set to convention' do
    assert_equal('convention', Yard::Lint::Validators::Tags::ForbiddenTags::Result.default_severity)
  end

  it 'class attributes has offense type set to tag' do
    assert_equal('tag', Yard::Lint::Validators::Tags::ForbiddenTags::Result.offense_type)
  end

  it 'class attributes has offense name set to forbiddentags' do
    assert_equal('ForbiddenTags', Yard::Lint::Validators::Tags::ForbiddenTags::Result.offense_name)
  end

  it 'build message delegates to messagesbuilder' do
    offense = {
      tag_name: 'return',
      types_text: 'void',
      pattern_types: 'void'
    }

    Yard::Lint::Validators::Tags::ForbiddenTags::MessagesBuilder
      .stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::ForbiddenTags::Result.new([])
    message = result.send(:build_message, offense)

    assert_equal('formatted message', message)
  end

  it 'inheritance inherits from results base' do
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::ForbiddenTags::Result.superclass)
  end
end
