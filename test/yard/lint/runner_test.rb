# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Runner' do
  attr_reader :selection, :config, :runner

  before do
    @selection = ['lib/example.rb']
    @config = Yard::Lint::Config.new
    @runner = Yard::Lint::Runner.new(selection, config)
  end

  it 'initialize stores selection as array' do
    assert_equal(['lib/example.rb'], runner.selection)
  end

  it 'initialize flattens nested arrays in selection' do
    nested_runner = Yard::Lint::Runner.new([['file1.rb'], 'file2.rb'], config)
    assert_equal(['file1.rb', 'file2.rb'], nested_runner.selection)
  end

  it 'initialize stores config' do
    assert_equal(config, runner.config)
  end

  it 'initialize uses default config when none provided' do
    default_runner = Yard::Lint::Runner.new(selection)
    assert_kind_of(Yard::Lint::Config, default_runner.config)
  end

  it 'initialize creates result builder with config' do
    assert_kind_of(Yard::Lint::ResultBuilder, runner.instance_variable_get(:@result_builder))
  end

  it 'run returns an aggregate result object' do
    result = runner.run
    assert_kind_of(Yard::Lint::Results::Aggregate, result)
  end

  it 'run orchestrates the validation process' do
    runner.expects(:run_validators).once.returns([])
    runner.expects(:parse_results).once.returns([])
    runner.expects(:build_result).once.returns(Yard::Lint::Results::Aggregate.new([], config))
    runner.run
  end

  it 'filter files for validator returns all files when validator has no exclusions' do
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns([])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal(files, result)
  end

  it 'filter files for validator filters files matching validator exclude patterns' do
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns(['spec/**/*'])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal(
      %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb app/models/user.rb],
      result
    )
  end

  it 'filter files for validator supports glob patterns with and' do
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns(['lib/**/*.rb'])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal(%w[spec/foo_spec.rb app/models/user.rb], result)
  end

  it 'filter files for validator handles multiple exclusion patterns' do
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns(['spec/**/*', 'app/**/*'])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal(
      %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb],
      result
    )
  end

  it 'filter files for validator supports simple wildcard patterns' do
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns(['lib/ba*.rb'])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal(
      %w[lib/foo.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb],
      result
    )
  end

  it 'filter files for validator returns empty array when all files are excluded' do
    files = %w[lib/foo.rb lib/bar.rb lib/baz/qux.rb spec/foo_spec.rb app/models/user.rb]
    config.stubs(:validator_exclude).with('Some/Validator').returns(['**/*'])

    result = runner.send(:filter_files_for_validator, 'Some/Validator', files)

    assert_equal([], result)
  end

  it 'integration processes enabled validators only' do
    custom_config = Yard::Lint::Config.new
    custom_config.stubs(:validator_enabled?).returns(false)
    custom_runner = Yard::Lint::Runner.new(selection, custom_config)

    result = custom_runner.run
    assert_equal(0, result.count)
  end
end

