# frozen_string_literal: true

describe 'InvalidTypes offense messages' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/invalid_types_messages.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
    end
  end

  it 'offense message names the invalid type rather than generic description' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    call_offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('call') }

    refute_nil(call_offense)
    assert_includes(call_offense[:message], 'invalid type(s)')
    refute_includes(call_offense[:message], 'at least one tag')
  end

  it 'offense message includes the @return invalid type' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    call_offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('call') }

    assert_includes(call_offense[:message], 'wrong_return_type')
    assert_includes(call_offense[:message], '@return')
  end

  it 'offense message includes the @param invalid type with param name' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    call_offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('call') }

    assert_includes(call_offense[:message], 'anything')
    assert_includes(call_offense[:message], '@param body')
  end

  it 'offense message lists multiple tag violations in a single offense' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    call_offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('call') }

    assert_match(/@param.*@return|@return.*@param/, call_offense[:message])
  end

  it 'offense message for single invalid type includes tag and type' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    process_offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('process') }

    refute_nil(process_offense)
    assert_includes(process_offense[:message], 'bad_type')
    assert_includes(process_offense[:message], '@param value')
  end
end
