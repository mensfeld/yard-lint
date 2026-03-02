# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::EmptyCommentLine::Result' do
  attr_reader :config, :parsed_data, :result

  before do
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::EmptyCommentLine::Result.new(@parsed_data, @config)
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

  it 'class attributes defines default severity as convention' do
    assert_equal('convention', Yard::Lint::Validators::Documentation::EmptyCommentLine::Result.default_severity)
  end

  it 'class attributes defines offense type as line' do
    assert_equal('line', Yard::Lint::Validators::Documentation::EmptyCommentLine::Result.offense_type)
  end

  it 'class attributes defines offense name as emptycommentline' do
    assert_equal('EmptyCommentLine', Yard::Lint::Validators::Documentation::EmptyCommentLine::Result.offense_name)
  end

  it 'build message delegates to messagesbuilder' do
    offense = {
      location: 'lib/example.rb',
      line: 5,
      object_line: 10,
      object_name: 'MyClass#process',
      violation_type: 'leading'
    }

    assert_includes(result.build_message(offense), 'leading')
    assert_includes(result.build_message(offense), 'MyClass#process')
  end
end

