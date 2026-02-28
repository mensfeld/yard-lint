# frozen_string_literal: true

require 'test_helper'

class YardLintRunnerTest < Minitest::Test
  attr_reader :config, :runner, :selection

  def setup
    @selection = ['lib/example.rb']
    @config = Yard::Lint::Config.new
    @runner = Yard::Lint::Runner.new(selection, config)
  end

  def test_initialize_stores_selection_as_array
    assert_equal(['lib/example.rb'], runner.selection)
  end

  def test_initialize_flattens_nested_arrays_in_selection
    nested_runner = Yard::Lint::Runner.new([['file1.rb'], 'file2.rb'], config)
    assert_equal(['file1.rb', 'file2.rb'], nested_runner.selection)
  end

  def test_initialize_stores_config
    assert_equal(config, runner.config)
  end

  def test_initialize_uses_default_config_when_none_provided
    default_runner = Yard::Lint::Runner.new(selection)
    assert_kind_of(Yard::Lint::Config, default_runner.config)
  end

  def test_initialize_creates_result_builder_with_config
    assert_kind_of(Yard::Lint::ResultBuilder, runner.instance_variable_get(:@result_builder))
  end

  def test_run_returns_an_aggregate_result_object
    result = runner.run
    assert_kind_of(Yard::Lint::Results::Aggregate, result)
  end

  def test_run_orchestrates_the_validation_process
    runner.expects(:run_validators).once.returns([])
    runner.expects(:parse_results).once.returns([])
    runner.expects(:build_result).once.returns(Yard::Lint::Results::Aggregate.new([], config))
    runner.run
  end

  def test_filter_files_for_validator_returns_all_files_when_validator_has_no_exclusions
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns([])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal(files, result)
  end

  def test_filter_files_for_validator_filters_files_matching_validator_exclude_patterns
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns(['spec/**/*'])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal(
      %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb app/models/user.rb],
      result
    )
  end

  def test_filter_files_for_validator_supports_glob_patterns_with_and
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns(['lib/**/*.rb'])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal(%w[spec/foo_spec.rb app/models/user.rb], result)
  end

  def test_filter_files_for_validator_handles_multiple_exclusion_patterns
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns(['spec/**/*', 'app/**/*'])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal(
      %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb],
      result
    )
  end

  def test_filter_files_for_validator_supports_simple_wildcard_patterns
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns(['lib/ba*.rb'])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal(
      %w[lib/foo.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb],
      result
    )
  end

  def test_filter_files_for_validator_returns_empty_array_when_all_files_are_excluded
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns(['**/*'])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal([], result)
  end

  def test_integration_processes_enabled_validators_only
    custom_config = Yard::Lint::Config.new
    custom_config.stubs(:validator_enabled?).returns(false)
    custom_runner = Yard::Lint::Runner.new(selection, custom_config)

    result = custom_runner.run
    assert_equal(0, result.count)
  end
end
