# frozen_string_literal: true

# Regression test: allowed default types (self, nil, true, false, void) inside
# generic/compound type expressions were incorrectly flagged as InvalidTagType
# because the sanitize logic concatenated type names (e.g., "Array<self>" became
# "Arrayself" which is not in ALLOWED_DEFAULTS and not a real class).
describe 'Generic Allowed Defaults' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/generic_allowed_defaults.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
    end
  end

  it 'does not produce any InvalidTagType offenses for allowed defaults in generics' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'InvalidTagType' }

    assert_empty(
      offenses,
      "Expected no InvalidTagType offenses but got: #{offenses.map { |o| o[:message] }}"
    )
  end

  it 'does not produce any InvalidTypeSyntax offenses for allowed defaults in generics' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_empty(
      offenses,
      "Expected no InvalidTypeSyntax offenses but got: #{offenses.map { |o| o[:message] }}"
    )
  end

  it 'accepts Array<self> in @return' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('array_of_self')
    end

    assert_nil(offense, 'Array<self> should not be flagged as invalid type')
  end

  it 'accepts Array<nil> in @return' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('array_of_nil')
    end

    assert_nil(offense, 'Array<nil> should not be flagged as invalid type')
  end

  it 'accepts Hash{Symbol => self} in @param' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('hash_value_self')
    end

    assert_nil(offense, 'Hash{Symbol => self} should not be flagged as invalid type')
  end

  it 'accepts Hash{Symbol => nil} in @param' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('hash_value_nil')
    end

    assert_nil(offense, 'Hash{Symbol => nil} should not be flagged as invalid type')
  end

  it 'accepts Hash{String => true} in @return' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('hash_value_true')
    end

    assert_nil(offense, 'Hash{String => true} should not be flagged as invalid type')
  end

  it 'accepts Hash{String => false} in @return' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('hash_value_false')
    end

    assert_nil(offense, 'Hash{String => false} should not be flagged as invalid type')
  end

  it 'accepts Array<Array<self>> (nested generics) in @return' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('nested_self')
    end

    assert_nil(offense, 'Array<Array<self>> should not be flagged as invalid type')
  end

  it 'accepts Hash{Symbol => Array<nil>} (deeply nested) in @param' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('deeply_nested_nil')
    end

    assert_nil(offense, 'Hash{Symbol => Array<nil>} should not be flagged as invalid type')
  end
end
