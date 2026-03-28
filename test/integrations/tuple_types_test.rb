# frozen_string_literal: true

# Regression test for https://github.com/mensfeld/yard-lint/issues/113
# Tuples (fixed-length arrays with different types per position) are valid YARD syntax
# documented at https://yardoc.org/types.html but were incorrectly flagged as InvalidTagType.
describe 'Tuple Types' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/tuple_types.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
    end
  end

  it 'does not produce any InvalidTagType offenses for tuple types' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'InvalidTagType' }

    assert_empty(
      offenses,
      "Expected no InvalidTagType offenses but got: #{offenses.map { |o| o[:message] }}"
    )
  end

  it 'does not produce any InvalidTypeSyntax offenses for tuple types' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_empty(
      offenses,
      "Expected no InvalidTypeSyntax offenses but got: #{offenses.map { |o| o[:message] }}"
    )
  end

  it 'accepts a simple tuple in @return' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('simple_tuple')
    end

    assert_nil(offense, 'Simple tuple (String, Integer) should not be flagged')
  end

  it 'accepts a tuple or nil in @return' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('tuple_or_nil')
    end

    assert_nil(offense, 'Tuple-or-nil return type should not be flagged')
  end

  it 'accepts a tuple with namespaced types' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('namespaced_tuple')
    end

    assert_nil(offense, 'Tuple with namespaced types should not be flagged')
  end

  it 'accepts a tuple in @param' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('tuple_param')
    end

    assert_nil(offense, 'Tuple in @param should not be flagged')
  end

  it 'accepts a three-element tuple' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('triple_tuple')
    end

    assert_nil(offense, 'Three-element tuple should not be flagged')
  end
end
