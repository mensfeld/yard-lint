# frozen_string_literal: true

require 'test_helper'

class ForbiddenTagsIntegrationTest < Minitest::Test
  attr_reader :fixture_path

  def setup
    @fixture_path = File.expand_path('../fixtures/forbidden_tags_examples.rb', __dir__)
  end

  def test_detecting_return_void_finds_return_void_tags
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
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

  def test_detecting_return_void_does_not_flag_return_boolean
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
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

  def test_detecting_return_void_does_not_flag_return_nil
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
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

  def test_detecting_return_void_flags_return_with_void_among_multiple_types
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
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

  def test_detecting_param_object_finds_param_object_tags
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
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

  def test_detecting_param_object_does_not_flag_param_string
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
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

  def test_detecting_tag_only_patterns_finds_api_tags
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
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

  def test_detecting_tag_only_patterns_provides_helpful_error_message
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
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

  def test_multiple_patterns_detects_all_configured_patterns
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
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

  def test_when_disabled_does_not_run_validation
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', false)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
               { 'Tag' => 'return', 'Types' => ['void'] }
             ])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    forbidden_offenses = result.offenses.select { |o| o[:name] == 'ForbiddenTags' }
    assert_empty(forbidden_offenses)
  end

  def test_with_empty_patterns_does_not_report_any_offenses
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    forbidden_offenses = result.offenses.select { |o| o[:name] == 'ForbiddenTags' }
    assert_empty(forbidden_offenses)
  end

  def test_error_messages_provides_descriptive_messages_for_type_patterns
    config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
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
