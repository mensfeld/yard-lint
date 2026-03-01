# frozen_string_literal: true

require 'test_helper'


describe 'Forbidden Tags' do
  attr_reader :fixture_path


  before do
    @fixture_path = File.expand_path('../fixtures/forbidden_tags_examples.rb', __dir__)
  end

  it 'detecting return void finds return void tags' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'return', 'Types' => ['void'] }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    void_offenses = result.offenses.select do |o|
      o[:name] == 'ForbiddenTags' &&
        o[:message].include?('@return') &&
        o[:message].include?('void')
    end

    refute_empty(void_offenses)
  end

  it 'detecting return void does not flag return boolean' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'return', 'Types' => ['void'] }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    boolean_offenses = result.offenses.select do |o|
      o[:name] == 'ForbiddenTags' &&
        o[:message].include?('Boolean')
    end

    assert_empty(boolean_offenses)
  end

  it 'detecting return void does not flag return nil' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'return', 'Types' => ['void'] }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    nil_offenses = result.offenses.select do |o|
      o[:name] == 'ForbiddenTags' &&
        o[:message].include?('[nil]')
    end

    assert_empty(nil_offenses)
  end

  it 'detecting return void flags return with void among multiple types' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'return', 'Types' => ['void'] }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # The mixed_return method has @return [String, void] which should be flagged
    # Look for offense on line 39 where mixed_return is defined
    mixed_offenses = result.offenses.select do |o|
      o[:name] == 'ForbiddenTags' &&
        o[:message].include?('String,void')
    end

    refute_empty(mixed_offenses)
  end

  it 'detecting param object finds param object tags' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'param', 'Types' => ['Object'] }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    object_offenses = result.offenses.select do |o|
      o[:name] == 'ForbiddenTags' &&
        o[:message].include?('@param') &&
        o[:message].include?('Object')
    end

    refute_empty(object_offenses)
  end

  it 'detecting param object does not flag param string' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'param', 'Types' => ['Object'] }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    string_offenses = result.offenses.select do |o|
      o[:name] == 'ForbiddenTags' &&
        o[:message].include?('String')
    end

    assert_empty(string_offenses)
  end

  it 'detecting tag only patterns finds api tags' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'api' }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    api_offenses = result.offenses.select do |o|
      o[:name] == 'ForbiddenTags' &&
        o[:message].include?('@api')
    end

    refute_empty(api_offenses)
  end

  it 'detecting tag only patterns provides helpful error message' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'api' }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'ForbiddenTags' && o[:message].include?('@api')
    end

    refute_nil(offense)
    assert_includes(offense[:message], 'not allowed by project configuration')
  end

  it 'multiple patterns detects all configured patterns' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'return', 'Types' => ['void'] },
               { 'Tag' => 'param', 'Types' => ['Object'] },
               { 'Tag' => 'api' }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    forbidden_offenses = result.offenses.select { |o| o[:name] == 'ForbiddenTags' }

    # Should find offenses for all three patterns
    void_found = forbidden_offenses.any? { |o| o[:message].include?('void') }
    object_found = forbidden_offenses.any? { |o| o[:message].include?('Object') }
    api_found = forbidden_offenses.any? { |o| o[:message].include?('@api') }

    assert_equal(true, void_found)
    assert_equal(true, object_found)
    assert_equal(true, api_found)
  end

  it 'when disabled does not run validation' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', false)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'return', 'Types' => ['void'] }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    forbidden_offenses = result.offenses.select { |o| o[:name] == 'ForbiddenTags' }
    assert_empty(forbidden_offenses)
  end

  it 'with empty patterns does not report any offenses' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    forbidden_offenses = result.offenses.select { |o| o[:name] == 'ForbiddenTags' }
    assert_empty(forbidden_offenses)
  end

  it 'error messages provides descriptive messages for type patterns' do
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'return', 'Types' => ['void'] }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'ForbiddenTags' }
    refute_nil(offense)
    assert_includes(offense[:message], 'Forbidden tag pattern detected')
    assert_includes(offense[:message], 'not allowed')
  end
end
