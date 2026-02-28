# frozen_string_literal: true

require 'test_helper'

class MultiValidatorComprehensiveIntegrationTest < Minitest::Test
  attr_reader :config, :fixture_path

  def setup
    @fixture_path = File.expand_path('fixtures/multi_validator_comprehensive.rb', __dir__)
  end

  # -- With default configuration --

  def setup_default_config
    @config = test_config
  end

  def test_with_default_configuration_detects_multiple_types_of_offenses_simultaneously
    setup_default_config

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense_names = result.offenses.map { |o| o[:name] }.uniq

    assert_includes(offense_names, 'InvalidTagOrder')
    assert_includes(offense_names, 'UnknownParameterName')
    assert_includes(offense_names, 'InvalidTypeSyntax')
    assert_operator(result.count, :>, 5)
  end

  def test_with_default_configuration_finds_offenses_across_multiple_scenarios_in_the_fixture
    setup_default_config

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    lines_with_issues = result.offenses.map { |o| o[:location_line] }.uniq

    assert_operator(lines_with_issues.size, :>=, 5)
  end

  def test_with_default_configuration_handles_kitchen_sink_method_with_many_issues
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
      c.send(:set_validator_config, 'Tags/Order', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
      c.send(:set_validator_config, 'Warnings/UnknownParameterName', 'Enabled', true)
      c.send(:set_validator_config, 'Warnings/DuplicatedParameterName', 'Enabled', true)
      c.send(:set_validator_config, 'Warnings/UnknownTag', 'Enabled', true)
    end
  end

  def test_multiple_validators_enabled_together_runs_all_enabled_validators_and_finds_multiple_issue_types
    setup_multiple_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense_names = result.offenses.map { |o| o[:name] }.uniq

    assert_includes(offense_names, 'InvalidTagOrder')
    assert_includes(offense_names, 'InvalidTypeSyntax')
    assert_includes(offense_names, 'UnknownParameterName')
  end

  def test_multiple_validators_enabled_together_detects_duplicate_parameter_names
    setup_multiple_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    duplicated = result.offenses.select { |o| o[:name] == 'DuplicatedParameterName' }
    refute_empty(duplicated)
  end

  def test_multiple_validators_enabled_together_detects_unknown_tags
    setup_multiple_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    unknown_tags = result.offenses.select { |o| o[:name] == 'UnknownTag' }
    refute_empty(unknown_tags)
  end

  # -- Type validation validators together --

  def setup_type_validators
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/InvalidTypes', 'Enabled', true)
    end
  end

  def test_type_validation_validators_together_runs_both_type_validators_without_conflicts
    setup_type_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    type_syntax = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }
    invalid_types = result.offenses.select { |o| o[:name] == 'InvalidTypes' }

    refute_empty(type_syntax)

    assert_kind_of(Array, type_syntax)
    assert_kind_of(Array, invalid_types)
  end

  def test_type_validation_validators_together_finds_multiple_type_syntax_errors
    setup_type_validators

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    type_syntax = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_operator(type_syntax.size, :>=, 3)
  end

  # -- Documentation validators together --

  def test_documentation_validators_together_detects_missing_method_argument_documentation
    @config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedMethodArguments', 'Enabled', true)
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    undocumented_args = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }

    refute_empty(undocumented_args)
  end

  # -- Performance with many validators --

  def setup_many_validators
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/Order', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/InvalidTypes', 'Enabled', true)
      c.send(:set_validator_config, 'Warnings/UnknownParameterName', 'Enabled', true)
      c.send(:set_validator_config, 'Warnings/DuplicatedParameterName', 'Enabled', true)
      c.send(:set_validator_config, 'Warnings/UnknownTag', 'Enabled', true)
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects', 'Enabled', true)
      c.send(:set_validator_config, 'Documentation/UndocumentedMethodArguments', 'Enabled', true)
    end
  end

  def test_performance_with_many_validators_completes_analysis_in_reasonable_time
    setup_many_validators

    start_time = Time.now
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    elapsed = Time.now - start_time

    assert_operator(elapsed, :<, 15)
    assert_operator(result.count, :>, 5)
  end

  def test_performance_with_many_validators_finds_offenses_from_multiple_validator_categories
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

  def test_performance_with_many_validators_produces_consistent_results_across_runs
    setup_many_validators

    result1 = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    result2 = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    assert_equal(result1.count, result2.count)
  end
end
