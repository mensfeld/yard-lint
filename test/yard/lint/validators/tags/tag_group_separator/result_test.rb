# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::TagGroupSeparator::Result' do
  attr_reader :config, :parsed_data, :result

  before do
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Tags::TagGroupSeparator::Result.new(@parsed_data, @config)
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

  it 'class methods defines default severity as convention' do
    assert_equal('convention', Yard::Lint::Validators::Tags::TagGroupSeparator::Result.default_severity)
  end

  it 'class methods defines offense type as method' do
    assert_equal('method', Yard::Lint::Validators::Tags::TagGroupSeparator::Result.offense_type)
  end

  it 'class methods defines offense name as missingtaggroupseparator' do
    assert_equal('MissingTagGroupSeparator', Yard::Lint::Validators::Tags::TagGroupSeparator::Result.offense_name)
  end

  it 'build message generates human readable message' do
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        method_name: 'call',
        separators: 'param->return'
      }
    ]
    r = Yard::Lint::Validators::Tags::TagGroupSeparator::Result.new(parsed_data, config)
    offense = r.offenses.first
    assert_includes(offense[:message], 'call')
    assert_includes(offense[:message], 'param')
    assert_includes(offense[:message], 'return')
  end
end

