# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::InvalidTypes::Result' do
  attr_reader :config, :parsed_data, :result

  before do
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Tags::InvalidTypes::Result.new(@parsed_data, @config)
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

  it 'class methods defines default severity' do
    assert_respond_to(Yard::Lint::Validators::Tags::InvalidTypes::Result, :default_severity)
  end

  it 'class methods defines offense type' do
    assert_respond_to(Yard::Lint::Validators::Tags::InvalidTypes::Result, :offense_type)
  end

  it 'class methods defines offense name' do
    assert_respond_to(Yard::Lint::Validators::Tags::InvalidTypes::Result, :offense_name)
  end
end

