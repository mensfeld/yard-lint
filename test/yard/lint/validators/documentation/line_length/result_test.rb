# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::LineLength::Result' do
  attr_reader :config, :parsed_data, :result

  before do
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::LineLength::Result.new(@parsed_data, @config)
  end

  it 'initialize inherits from results base' do
    assert_kind_of(Yard::Lint::Results::Base, result)
  end

  it 'offenses returns an array' do
    assert_kind_of(Array, result.offenses)
  end

  it 'offenses handles empty parsed data' do
    assert_equal([], result.offenses)
  end

  it 'class attributes defines default severity as convention' do
    assert_equal('convention', Yard::Lint::Validators::Documentation::LineLength::Result.default_severity)
  end

  it 'class attributes defines offense type as line' do
    assert_equal('line', Yard::Lint::Validators::Documentation::LineLength::Result.offense_type)
  end

  it 'class attributes defines offense name as linelength' do
    assert_equal('LineLength', Yard::Lint::Validators::Documentation::LineLength::Result.offense_name)
  end

  it 'build message includes length and max_length from offense data' do
    parsed = [
      {
        location: 'lib/example.rb',
        line: 5,
        object_line: 10,
        object_name: 'MyClass#process',
        length: 135,
        max_length: 120
      }
    ]
    r = Yard::Lint::Validators::Documentation::LineLength::Result.new(parsed, config)
    msg = r.offenses.first[:message]
    assert_includes(msg, '135')
    assert_includes(msg, '120')
    assert_includes(msg, 'MyClass#process')
  end
end
