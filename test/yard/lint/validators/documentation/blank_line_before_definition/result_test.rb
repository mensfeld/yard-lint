# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result' do
  attr_reader :config, :parsed_data, :result

  before do
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.new(@parsed_data, @config)
  end

  it 'initialize inherits from results base' do
    assert_kind_of(Yard::Lint::Results::Base, @result)
  end

  it 'initialize stores config' do
    assert_equal(@config, @result.instance_variable_get(:@config))
  end

  it 'offenses returns an array' do
    assert_kind_of(Array, @result.offenses)
  end

  it 'offenses handles empty parsed data' do
    assert_equal([], @result.offenses)
  end

  it 'class defines default severity as convention' do
    assert_equal('convention', Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.default_severity)
  end

  it 'class defines offense type as line' do
    assert_equal('line', Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.offense_type)
  end

  it 'class defines offense name as blank line before definition' do
    assert_equal('BlankLineBeforeDefinition', Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.offense_name)
  end

  it 'build message delegates to messages builder' do
    offense = {
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#process',
      violation_type: 'single',
      blank_count: 1
    }

    assert_includes(@result.build_message(offense), 'Blank line')
    assert_includes(@result.build_message(offense), 'MyClass#process')
  end

  it 'severity for single blank line uses default' do
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        object_name: 'MyClass#process',
        violation_type: 'single',
        blank_count: 1
      }
    ]

    result = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.new(parsed_data, @config)
    assert_equal('convention', result.offenses.first[:severity])
  end

  it 'severity for orphaned documentation uses orphaned severity' do
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 15,
        object_name: 'MyClass#execute',
        violation_type: 'orphaned',
        blank_count: 2
      }
    ]

    result = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.new(parsed_data, @config)
    assert_equal('convention', result.offenses.first[:severity])
  end
end

