# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Documentation::MissingReturn::Result' do
  attr_reader :config, :parsed_data, :result


  before do
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::MissingReturn::Result.new(@parsed_data, @config)
  end

  it 'initialize inherits from results base' do
    assert_kind_of(Yard::Lint::Results::Base, result)
  end

  it 'initialize stores config' do
    assert_equal(config, result.instance_variable_get(:@config))
  end

  it 'offenses returns an array' do
    assert_kind_of(Array, result.offenses)
  end

  it 'offenses handles empty parsed data' do
    assert_equal([], result.offenses)
  end

  it 'offenses with parsed data builds offenses from parsed data' do
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        element: 'Calculator#add'
      }
    ]
    result = Yard::Lint::Validators::Documentation::MissingReturn::Result.new(parsed_data, config)

    offenses = result.offenses
    refute_empty(offenses)
    assert_equal('lib/example.rb', offenses.first[:location])
    assert_equal(10, offenses.first[:location_line])
    assert_equal('MissingReturnTag', offenses.first[:name])
  end

  it 'offenses with parsed data includes message from messagesbuilder' do
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        element: 'Calculator#add'
      }
    ]
    result = Yard::Lint::Validators::Documentation::MissingReturn::Result.new(parsed_data, config)

    offenses = result.offenses
    assert_includes(offenses.first[:message], 'Missing @return tag for `Calculator#add`')
  end

  it 'offenses with parsed data sets offense type to line' do
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        element: 'Calculator#add'
      }
    ]
    result = Yard::Lint::Validators::Documentation::MissingReturn::Result.new(parsed_data, config)

    offenses = result.offenses
    assert_equal('line', offenses.first[:type])
  end

  it 'offenses with parsed data sets default severity to warning' do
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        element: 'Calculator#add'
      }
    ]
    result = Yard::Lint::Validators::Documentation::MissingReturn::Result.new(parsed_data, config)

    offenses = result.offenses
    assert_equal('warning', offenses.first[:severity])
  end

  it 'class methods defines default severity' do
    assert_respond_to(Yard::Lint::Validators::Documentation::MissingReturn::Result, :default_severity)
  end

  it 'class methods defines offense type' do
    assert_respond_to(Yard::Lint::Validators::Documentation::MissingReturn::Result, :offense_type)
  end

  it 'class methods defines offense name' do
    assert_respond_to(Yard::Lint::Validators::Documentation::MissingReturn::Result, :offense_name)
  end

  it 'class methods returns warning as default severity' do
    assert_equal('warning', Yard::Lint::Validators::Documentation::MissingReturn::Result.default_severity)
  end

  it 'class methods returns line as offense type' do
    assert_equal('line', Yard::Lint::Validators::Documentation::MissingReturn::Result.offense_type)
  end

  it 'class methods returns missingreturntag as offense name' do
    assert_equal('MissingReturnTag', Yard::Lint::Validators::Documentation::MissingReturn::Result.offense_name)
  end

  it 'build message delegates to messagesbuilder' do
    offense = { element: 'Example#method' }

    Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder
      .expects(:call).with(offense).returns('test message')

    result.build_message(offense)
  end
end
