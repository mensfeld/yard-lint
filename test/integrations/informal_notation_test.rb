# frozen_string_literal: true

require 'test_helper'

describe 'Informal Notation' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/informal_notation_examples.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/InformalNotation', 'Enabled', true)
    end
  end

  it 'detecting informal notation patterns finds note patterns' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    note_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'Note:'")
    end

    refute_empty(note_offenses)
    assert_includes(note_offenses.first[:message], '@note')
  end

  it 'detecting informal notation patterns finds todo patterns' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    todo_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'Todo:'")
    end

    refute_empty(todo_offenses)
    assert_includes(todo_offenses.first[:message], '@todo')
  end

  it 'detecting informal notation patterns finds see patterns' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    see_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'See:'")
    end

    refute_empty(see_offenses)
    assert_includes(see_offenses.first[:message], '@see')
  end

  it 'detecting informal notation patterns finds warning patterns' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    warning_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'Warning:'")
    end

    refute_empty(warning_offenses)
    assert_includes(warning_offenses.first[:message], '@deprecated')
  end

  it 'detecting informal notation patterns finds deprecated patterns' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    deprecated_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'Deprecated:'")
    end

    refute_empty(deprecated_offenses)
    assert_includes(deprecated_offenses.first[:message], '@deprecated')
  end

  it 'detecting informal notation patterns finds fixme patterns' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    fixme_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'FIXME:'")
    end

    refute_empty(fixme_offenses)
    assert_includes(fixme_offenses.first[:message], '@todo')
  end

  it 'detecting informal notation patterns finds important patterns' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    important_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?("'IMPORTANT:'")
    end

    refute_empty(important_offenses)
    assert_includes(important_offenses.first[:message], '@note')
  end

  it 'detecting informal notation patterns does not flag patterns inside code blocks' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # The with_code_block method has patterns inside ```, should not be flagged
    code_block_method_offenses = result.offenses.select do |o|
      o[:name] == 'InformalNotation' &&
        o[:message].include?('inside a code block')
    end

    assert_empty(code_block_method_offenses)
  end

  it 'detecting informal notation patterns does not flag proper yard tags' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # Methods with proper @note and @todo tags should not be flagged for those
    offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }

    # None of the offenses should be about proper YARD tag syntax
    offenses.each do |offense|
      refute_includes(offense[:message], '@note This is a proper')
      refute_includes(offense[:message], '@todo This is a proper')
    end
  end

  it 'when disabled does not run validation' do
    disabled_config = test_config do |c|
      c.set_validator_config('Tags/InformalNotation', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    informal_notation_offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }
    assert_empty(informal_notation_offenses)
  end

  it 'case sensitivity configuration matches patterns case insensitively by default' do
    case_insensitive_config = test_config do |c|
      c.set_validator_config('Tags/InformalNotation', 'Enabled', true)
      c.set_validator_config('Tags/InformalNotation', 'CaseSensitive', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: case_insensitive_config, progress: false)

    # Should find patterns regardless of case
    offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }
    refute_empty(offenses)
  end
end

