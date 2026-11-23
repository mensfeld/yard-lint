# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UndocumentedObjects::Result' do
  attr_reader :config, :parsed_data, :result

  before do
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::UndocumentedObjects::Result.new(@parsed_data, @config)
  end

  it 'initialize inherits from results base' do
    assert_kind_of(Yard::Lint::Results::Base, result)
  end

  it 'initialize stores config' do
    assert_equal(config, result.config)
  end

  it 'offenses returns an array' do
    assert_kind_of(Array, result.offenses)
  end

  it 'offenses handles empty parsed data' do
    assert_equal([], result.offenses)
  end

  it 'class methods defines default severity' do
    assert_respond_to(Yard::Lint::Validators::Documentation::UndocumentedObjects::Result, :default_severity)
  end

  it 'class methods defines offense type' do
    assert_respond_to(Yard::Lint::Validators::Documentation::UndocumentedObjects::Result, :offense_type)
  end

  it 'class methods defines offense name' do
    assert_respond_to(Yard::Lint::Validators::Documentation::UndocumentedObjects::Result, :offense_name)
  end

  it 'offenses use the documentation required message for an undocumented object' do
    result = Yard::Lint::Validators::Documentation::UndocumentedObjects::Result.new(
      [{ location: 'a.rb', line: 3, element: 'Checker#ready?' }], config
    )

    assert_equal('Documentation required for `Checker#ready?`', result.offenses.first[:message])
  end

  it 'offenses name the missing return tag for a combined boolean method offense' do
    result = Yard::Lint::Validators::Documentation::UndocumentedObjects::Result.new(
      [{ location: 'a.rb', line: 3, element: 'Checker#enabled?', method_name: 'enabled?' }], config
    )

    assert_equal('The `Checker#enabled?` method has no @return tag', result.offenses.first[:message])
  end
end
