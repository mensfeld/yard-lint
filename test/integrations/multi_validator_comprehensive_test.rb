# frozen_string_literal: true

require 'test_helper'

describe 'Multi Validator Comprehensive' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('fixtures/multi_validator_comprehensive.rb', __dir__)
  end

  # -- With default configuration --

  def setup_default_config
    @config = test_config
  end

  it 'with default configuration detects multiple types of offenses simultaneously' do
    setup_default_config

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense_names = result.offenses.map { |o| o[:name] }.uniq

    assert_includes(offense_names, 'InvalidTagOrder')
    assert_includes(offense_names, 'UnknownParameterName')
    assert_includes(offense_names, 'InvalidTypeSyntax')
    assert_operator(result.count, :>, 5)
  end

  it 'with default configuration finds offenses across multiple scenarios in the fixture' do
    setup_default_config

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    lines_with_issues = result.offenses.map { |o| o[:location_line] }.uniq

    assert_operator(lines_with_issues.size, :>=, 5)
  end

  it 'with default configuration handles kitchen sink method with many issues' do
    setup_default_config

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    kitchen_sink_offenses = result.offenses.select do |o|
      o[:location_line] == 89
    end

    assert_operator(kitchen_sink_offenses.size, :>=, 3)
    assert_operator(kitchen_sink_offenses.map { |o| o[:name] }.uniq.size, :>=, 2)
  end

  # -- Multiple validators enabled together --

  def setup_multiple_validators
    @config = test_config do |c|
      c.set_validator_config('Tags/Order', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
      c.set_validator_config('Warnings/UnknownParameterName', 'Enabled', true)
      c.set_validator_config('Warnings/DuplicatedParameterName', 'Enabled', true)
      c.set_validator_config('Warnings/UnknownTag', 'Enabled', true)
    end
  end

  it 'multiple validators enabled together runs all enabled validators and finds multiple issue types' do
    setup_multiple_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense_names = result.offenses.map { |o| o[:name] }.uniq

    assert_includes(offense_names, 'InvalidTagOrder')
    assert_includes(offense_names, 'InvalidTypeSyntax')
    assert_includes(offense_names, 'UnknownParameterName')
  end

  it 'multiple validators enabled together detects duplicate parameter names' do
    setup_multiple_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    duplicated = result.offenses.select { |o| o[:name] == 'DuplicatedParameterName' }
    refute_empty(duplicated)
  end

  it 'multiple validators enabled together detects unknown tags' do
    setup_multiple_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    unknown_tags = result.offenses.select { |o| o[:name] == 'UnknownTag' }
    refute_empty(unknown_tags)
  end

  # -- Type validation validators together --

  def setup_type_validators
    @config = test_config do |c|
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
    end
  end

  it 'type validation validators together runs both type validators without conflicts' do
    setup_type_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    type_syntax = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }
    invalid_types = result.offenses.select { |o| o[:name] == 'InvalidTypes' }

    refute_empty(type_syntax)

    assert_kind_of(Array, type_syntax)
    assert_kind_of(Array, invalid_types)
  end

  it 'type validation validators together finds multiple type syntax errors' do
    setup_type_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    type_syntax = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_operator(type_syntax.size, :>=, 3)
  end

  # -- Documentation validators together --

  it 'documentation validators together detects missing method argument documentation' do
    @config = test_config do |c|
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', true)
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    undocumented_args = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }

    refute_empty(undocumented_args)
  end

  # -- Performance with many validators --

  def setup_many_validators
    @config = test_config do |c|
      c.set_validator_config('Tags/Order', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Warnings/UnknownParameterName', 'Enabled', true)
      c.set_validator_config('Warnings/DuplicatedParameterName', 'Enabled', true)
      c.set_validator_config('Warnings/UnknownTag', 'Enabled', true)
      c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', true)
    end
  end

  it 'performance with many validators completes analysis in reasonable time' do
    setup_many_validators

    start_time = Time.now
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    elapsed = Time.now - start_time

    assert_operator(elapsed, :<, 15)
    assert_operator(result.count, :>, 5)
  end

  it 'performance with many validators finds offenses from multiple validator categories' do
    setup_many_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense_names = result.offenses.map { |o| o[:name] }.uniq

    has_tags = offense_names.any? { |n| %w[InvalidTagOrder InvalidTypeSyntax].include?(n) }
    has_warnings = offense_names.any? do |n|
      %w[UnknownParameterName DuplicatedParameterName].include?(n)
    end
    has_documentation = offense_names.any? { |n| n.start_with?('Undocumented') }

    assert_equal(true, has_tags)
    assert_equal(true, has_warnings)
    assert_equal(true, has_documentation)
  end

  it 'performance with many validators produces consistent results across runs' do
    setup_many_validators

    result1 = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    result2 = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    assert_equal(result1.count, result2.count)
  end
end

