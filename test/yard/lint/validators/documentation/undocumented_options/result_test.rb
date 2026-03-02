# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Documentation::UndocumentedOptions::Result' do
  attr_reader :config, :parsed_data, :result

  before do
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.new(parsed_data, config)
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

  it 'offenses formats message for offense with options parameter' do
    parsed_offense = {
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#process',
      params: 'data, options = {}'
    }
    result_with_offense = Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.new([parsed_offense], config)
    built_offense = result_with_offense.offenses.first

    assert_equal(
      "Method 'MyClass#process' has options parameter (data, options = {}) " \
      'but no @option tags in documentation.',
      built_offense[:message]
    )
  end

  it 'offenses formats message for offense with kwargs' do
    parsed_offense = {
      location: 'lib/example.rb',
      line: 15,
      object_name: 'MyClass#configure',
      params: '**options'
    }
    result_with_offense = Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.new([parsed_offense], config)
    built_offense = result_with_offense.offenses.first

    assert_equal(
      "Method 'MyClass#configure' has options parameter (**options) " \
      'but no @option tags in documentation.',
      built_offense[:message]
    )
  end

  it 'class methods has correct default severity' do
    assert_equal('warning', Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.default_severity)
  end

  it 'class methods has correct offense type' do
    assert_equal('line', Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.offense_type)
  end

  it 'class methods has correct offense name' do
    assert_equal('UndocumentedOptions', Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.offense_name)
  end
end

