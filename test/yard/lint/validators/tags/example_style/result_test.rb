# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::ExampleStyle::Result' do
  it 'class attributes has convention default severity' do
    assert_equal('convention', Yard::Lint::Validators::Tags::ExampleStyle::Result.default_severity)
  end

  it 'class attributes has line offense type' do
    assert_equal('line', Yard::Lint::Validators::Tags::ExampleStyle::Result.offense_type)
  end

  it 'class attributes has examplestyleoffense as offense name' do
    assert_equal('ExampleStyleOffense', Yard::Lint::Validators::Tags::ExampleStyle::Result.offense_name)
  end

  it 'initialize inherits from result base class' do
    result = Yard::Lint::Validators::Tags::ExampleStyle::Result.new([])
    assert_kind_of(Yard::Lint::Results::Base, result)
  end

  it 'initialize builds offenses from parsed data' do
    parsed_data = [
      {
        name: 'ExampleStyle',
        object_name: 'User#initialize',
        example_name: 'Basic usage',
        cop_name: 'Style/StringLiterals',
        message: 'Prefer single-quoted strings',
        location: 'lib/user.rb',
        line: 10
      }
    ]

    result = Yard::Lint::Validators::Tags::ExampleStyle::Result.new(parsed_data)
    assert_equal(1, result.offenses.length)
    assert_equal('convention', result.offenses.first[:severity])
    assert_equal('ExampleStyle', result.offenses.first[:name])
  end

  it 'initialize respects configured severity from config' do
    parsed_data = [
      {
        name: 'ExampleStyle',
        object_name: 'User#initialize',
        example_name: 'Basic usage',
        cop_name: 'Style/StringLiterals',
        message: 'Prefer single-quoted strings',
        location: 'lib/user.rb',
        line: 10
      }
    ]

    config = mock('config')
    config.stubs(:validator_severity).with('Tags/ExampleStyle').returns('warning')

    result = Yard::Lint::Validators::Tags::ExampleStyle::Result.new(parsed_data, config)
    assert_equal('warning', result.offenses.first[:severity])
  end

  it 'build message delegates to messagesbuilder' do
    parsed_data = [
      {
        name: 'ExampleStyle',
        object_name: 'User#initialize',
        example_name: 'Basic usage',
        cop_name: 'Style/StringLiterals',
        message: 'Prefer single-quoted strings',
        location: 'lib/user.rb',
        line: 10
      }
    ]

    result = Yard::Lint::Validators::Tags::ExampleStyle::Result.new(parsed_data)
    offense = result.offenses.first

    assert_includes(offense[:message], 'User#initialize')
    assert_includes(offense[:message], 'Style/StringLiterals')
    assert_includes(offense[:message], 'Prefer single-quoted strings')
  end
end
