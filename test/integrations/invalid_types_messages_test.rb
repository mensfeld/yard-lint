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

  # -- Nested Hash types (regression for issue #151/#152 "complex hash values") --

  it 'does not flag two-level nested Hash return type' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('nested_hash_two_levels') }

    assert_nil(offense)
  end

  it 'does not flag three-level nested Hash return type' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('nested_hash_three_levels') }

    assert_nil(offense)
  end

  it 'does not flag Hash inside Array inside Hash param type' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('hash_in_array_in_hash') }

    assert_nil(offense)
  end

  it 'does not flag simple one-level Hash type' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('simple_hash') }

    assert_nil(offense)
  end

  it 'still flags an invalid type nested inside a Hash value' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('hash_with_invalid_value') }

    refute_nil(offense)
    assert_includes(offense[:message], 'bad_nested_type')
  end

  # -- YARD pseudo-types: undefined, unspecified, unknown --

  it 'does not flag Hash with undefined value type' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('hash_with_undefined_value') }

    assert_nil(offense)
  end

  it 'does not flag Hash with unspecified value type' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('hash_with_unspecified_value') }

    assert_nil(offense)
  end

  it 'does not flag Hash with unknown value type' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('hash_with_unknown_value') }

    assert_nil(offense)
  end

  it 'does not flag deeply nested Hash containing undefined' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('hash_nested_with_undefined') }

    assert_nil(offense)
  end

  it 'does not flag standalone undefined return type' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('standalone_undefined') }

    assert_nil(offense)
  end
end
