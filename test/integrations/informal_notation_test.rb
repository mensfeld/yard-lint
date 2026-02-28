# frozen_string_literal: true

require 'test_helper'

class InformalNotationIntegrationTest < Minitest::Test
  attr_reader :config, :fixture_path

  def setup
    @fixture_path = File.expand_path('../fixtures/informal_notation_examples.rb', __dir__)
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/InformalNotation', 'Enabled', true)
    end
  end

  def test_detecting_informal_notation_patterns_finds_note_patterns
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    note_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'Note:'")
    end

    refute_empty(note_offenses)
    assert_includes(note_offenses.first[:message], '@note')
  end

  def test_detecting_informal_notation_patterns_finds_todo_patterns
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    todo_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'Todo:'")
    end

    refute_empty(todo_offenses)
    assert_includes(todo_offenses.first[:message], '@todo')
  end

  def test_detecting_informal_notation_patterns_finds_see_patterns
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    see_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'See:'")
    end

    refute_empty(see_offenses)
    assert_includes(see_offenses.first[:message], '@see')
  end

  def test_detecting_informal_notation_patterns_finds_warning_patterns
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    warning_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'Warning:'")
    end

    refute_empty(warning_offenses)
    assert_includes(warning_offenses.first[:message], '@deprecated')
  end

  def test_detecting_informal_notation_patterns_finds_deprecated_patterns
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    deprecated_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'Deprecated:'")
    end

    refute_empty(deprecated_offenses)
    assert_includes(deprecated_offenses.first[:message], '@deprecated')
  end

  def test_detecting_informal_notation_patterns_finds_fixme_patterns
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    fixme_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'FIXME:'")
    end

    refute_empty(fixme_offenses)
    assert_includes(fixme_offenses.first[:message], '@todo')
  end

  def test_detecting_informal_notation_patterns_finds_important_patterns
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    important_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'IMPORTANT:'")
    end

    refute_empty(important_offenses)
    assert_includes(important_offenses.first[:message], '@note')
  end

  def test_detecting_informal_notation_patterns_does_not_flag_patterns_inside_code_blocks
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # The with_code_block method has patterns inside ```, should not be flagged
    code_block_method_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?('inside a code block')
    end

    assert_empty(code_block_method_offenses)
  end

  def test_detecting_informal_notation_patterns_does_not_flag_proper_yard_tags
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # Methods with proper @note and @todo tags should not be flagged for those
    offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }

    # None of the offenses should be about proper YARD tag syntax
    offenses.each do |offense|
      refute_includes(offense[:message], '@note This is a proper')
      refute_includes(offense[:message], '@todo This is a proper')
    end
  end

  def test_when_disabled_does_not_run_validation
    disabled_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/InformalNotation', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    informal_notation_offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }
    assert_empty(informal_notation_offenses)
  end

  def test_case_sensitivity_configuration_matches_patterns_case_insensitively_by_default
    case_insensitive_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/InformalNotation', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/InformalNotation', 'CaseSensitive', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: case_insensitive_config, progress: false)

    # Should find patterns regardless of case
    offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }
    refute_empty(offenses)
  end
end
