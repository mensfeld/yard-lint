# frozen_string_literal: true

require 'test_helper'

describe 'Type Syntax' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/type_syntax_examples.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
    end
  end

  it 'detecting type syntax errors detects unclosed bracket in param tag' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Array<')
    end

    refute_nil(offense)
    assert_equal(fixture_path, offense[:location])
    assert_equal('warning', offense[:severity])
    assert_includes(offense[:message], 'Invalid type syntax')
    assert_includes(offense[:message], '@param')
  end

  it 'detecting type syntax errors detects empty generic in return tag' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Array<>')
    end

    refute_nil(offense)
    assert_includes(offense[:message], '@return')
  end

  it 'detecting type syntax errors detects unclosed hash syntax' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Hash{Symbol =>')
    end

    refute_nil(offense)
    assert_includes(offense[:message], 'Invalid type syntax')
  end

  it 'detecting type syntax errors detects malformed hash syntax' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Hash{Symbol]')
    end

    refute_nil(offense)
  end

  it 'detecting type syntax errors does not flag valid type syntax' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # Should not flag valid_types method
    valid_offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('valid_types')
    end

    assert_nil(valid_offense)
  end

  it 'detecting type syntax errors does not flag multiple types union syntax' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # Should not flag multiple_types method
    union_offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('String, Integer')
    end

    assert_nil(union_offense)
  end

  it 'detecting type syntax errors does not flag nested generics' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # Should not flag nested_generics method
    nested_offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Array<Array<Integer>>')
    end

    assert_nil(nested_offense)
  end

  it 'validator configuration when typesyntax validator is disabled does not report type syntax violations' do
    disabled_config = test_config do |c|
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    type_syntax_offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_empty(type_syntax_offenses)
  end

  it 'validator configuration when validatedtags is customized only validates specified tags' do
    custom_config = test_config do |c|
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'ValidatedTags', ['return'])
    end

    result = Yard::Lint.run(path: fixture_path, config: custom_config, progress: false)

    type_syntax_offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

    # Should find @return violations but not @param violations
    return_offenses = type_syntax_offenses.select { |o| o[:message].include?('@return') }
    param_offenses = type_syntax_offenses.select { |o| o[:message].include?('@param') }

    refute_empty(return_offenses)
    assert_empty(param_offenses)
  end

  it 'offense details includes file path in location' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_equal(fixture_path, offense[:location])
    refute_empty(offense[:location])
  end

  it 'offense details includes line number' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_operator(offense[:location_line], :>, 0)
  end

  it 'offense details includes descriptive message with error details' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_includes(offense[:message], 'Invalid type syntax')
    assert_match(/@(param|return|option)/, offense[:message])
  end
end

