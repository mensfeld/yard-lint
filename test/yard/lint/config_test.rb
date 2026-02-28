# frozen_string_literal: true

require 'tmpdir'
require 'test_helper'

class YardLintConfigTest < Minitest::Test
  def test_initialize_sets_default_values
    config = Yard::Lint::Config.new

    assert_equal([], config.options)
    assert_equal(
      Yard::Lint::Validators::Tags::Order::Config.defaults['EnforcedOrder'],
      config.validator_config('Tags/Order', 'EnforcedOrder')
    )
    assert_equal(
      Yard::Lint::Validators::Tags::InvalidTypes::Config.defaults['ValidatedTags'],
      config.validator_config('Tags/InvalidTypes', 'ValidatedTags')
    )
    assert_equal([], config.validator_config('Tags/InvalidTypes', 'ExtraTypes'))
    assert_includes(config.exclude, '\.git')
    assert_includes(config.exclude, 'vendor/**/*')
    assert_includes(config.exclude, 'node_modules/**/*')
    assert_includes(config.exclude, 'spec/**/*')
    assert_includes(config.exclude, 'test/**/*')
    assert_equal('warning', config.fail_on_severity)
    assert_equal(false, config.validator_enabled?('Tags/ApiTags'))
    assert_equal(
      Yard::Lint::Validators::Tags::ApiTags::Config.defaults['AllowedApis'],
      config.validator_config('Tags/ApiTags', 'AllowedApis')
    )
    assert_equal(true, config.validator_enabled?('Semantic/AbstractMethods'))
    assert_equal(true, config.validator_enabled?('Tags/OptionTags'))
  end

  def test_initialize_accepts_a_block_for_configuration
    config = Yard::Lint::Config.new do |c|
      c.options = ['--private']
      c.send(:set_validator_config, 'Tags/Order', 'EnforcedOrder', %w[param return])
      c.send(:set_validator_config, 'Tags/InvalidTypes', 'ExtraTypes', ['CustomType'])
      c.exclude = ['spec/**/*']
      c.fail_on_severity = 'error'
      c.send(:set_validator_config, 'Tags/ApiTags', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ApiTags', 'AllowedApis', %w[public private])
      c.send(:set_validator_config, 'Semantic/AbstractMethods', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/OptionTags', 'Enabled', true)
    end

    assert_equal(['--private'], config.options)
    assert_equal(%w[param return], config.validator_config('Tags/Order', 'EnforcedOrder'))
    assert_equal(['CustomType'], config.validator_config('Tags/InvalidTypes', 'ExtraTypes'))
    assert_equal(['spec/**/*'], config.exclude)
    assert_equal('error', config.fail_on_severity)
    assert_equal(true, config.validator_enabled?('Tags/ApiTags'))
    assert_equal(%w[public private], config.validator_config('Tags/ApiTags', 'AllowedApis'))
    assert_equal(true, config.validator_enabled?('Semantic/AbstractMethods'))
    assert_equal(true, config.validator_enabled?('Tags/OptionTags'))
  end

  def test_from_file_raises_an_error_if_file_does_not_exist
    error = assert_raises(Yard::Lint::Errors::ConfigFileNotFoundError) do
      Yard::Lint::Config.from_file('/nonexistent/file.yml')
    end
    assert_match(/Config file not found/, error.message)
  end

  def test_from_file_loads_configuration_from_yaml_file
    config_file = '/tmp/test-yard-lint.yml'

    File.write(config_file, <<~YAML)
      AllValidators:
        YardOptions:
          - --private
          - --protected
        Exclude:
          - spec/**/*
          - vendor/**/*
        FailOnSeverity: error

      Tags/Order:
        EnforcedOrder:
          - param
          - return
          - raise

      Tags/InvalidTypes:
        ValidatedTags:
          - param
          - return
        ExtraTypes:
          - CustomType
          - MyType

      Tags/ApiTags:
        Enabled: true
        AllowedApis:
          - public
          - private

      Semantic/AbstractMethods:
        Enabled: true

      Tags/OptionTags:
        Enabled: true
    YAML

    config = Yard::Lint::Config.from_file(config_file)

    assert_equal(['--private', '--protected'], config.options)
    assert_equal(%w[param return raise], config.validator_config('Tags/Order', 'EnforcedOrder'))
    assert_equal(%w[param return], config.validator_config('Tags/InvalidTypes', 'ValidatedTags'))
    assert_equal(%w[CustomType MyType], config.validator_config('Tags/InvalidTypes', 'ExtraTypes'))
    assert_equal(['spec/**/*', 'vendor/**/*'], config.exclude)
    assert_equal('error', config.fail_on_severity)
    assert_equal(true, config.validator_enabled?('Tags/ApiTags'))
    assert_equal(%w[public private], config.validator_config('Tags/ApiTags', 'AllowedApis'))
    assert_equal(true, config.validator_enabled?('Semantic/AbstractMethods'))
    assert_equal(true, config.validator_enabled?('Tags/OptionTags'))
  ensure
    FileUtils.rm_f(config_file)
  end

  def test_from_file_uses_defaults_for_missing_keys
    config_file = '/tmp/test-yard-lint.yml'

    File.write(config_file, <<~YAML)
      AllValidators:
        YardOptions:
          - --private
    YAML

    config = Yard::Lint::Config.from_file(config_file)

    assert_equal(['--private'], config.options)
    assert_equal(
      Yard::Lint::Validators::Tags::Order::Config.defaults['EnforcedOrder'],
      config.validator_config('Tags/Order', 'EnforcedOrder')
    )
    assert_includes(config.exclude, '\.git')
    assert_includes(config.exclude, 'vendor/**/*')
    assert_includes(config.exclude, 'node_modules/**/*')
  ensure
    FileUtils.rm_f(config_file)
  end

  def test_load_returns_nil_if_no_config_file_is_found
    Yard::Lint::Config.stubs(:find_config_file).returns(nil)

    assert_nil(Yard::Lint::Config.load)
  end

  def test_load_loads_config_file_if_found
    config_path = '/tmp/.yard-lint.yml'
    Yard::Lint::Config.stubs(:find_config_file).returns(config_path)
    File.stubs(:exist?).with(config_path).returns(true)
    YAML.stubs(:load_file).with(config_path).returns({})

    config = Yard::Lint::Config.load

    assert_kind_of(Yard::Lint::Config, config)
  end

  def test_find_config_file_finds_config_file_in_current_directory
    Dir.mktmpdir do |dir|
      config_file = File.join(dir, Yard::Lint::Config::DEFAULT_CONFIG_FILE)
      File.write(config_file, '')

      assert_equal(config_file, Yard::Lint::Config.find_config_file(dir))
    end
  end

  def test_find_config_file_finds_config_file_in_parent_directory
    Dir.mktmpdir do |parent_dir|
      config_file = File.join(parent_dir, Yard::Lint::Config::DEFAULT_CONFIG_FILE)
      File.write(config_file, '')

      child_dir = File.join(parent_dir, 'child')
      Dir.mkdir(child_dir)

      assert_equal(config_file, Yard::Lint::Config.find_config_file(child_dir))
    end
  end

  def test_find_config_file_returns_nil_if_no_config_file_is_found
    Dir.mktmpdir do |dir|
      assert_nil(Yard::Lint::Config.find_config_file(dir))
    end
  end

  def test_allows_hash_like_access_to_attributes
    config = Yard::Lint::Config.new

    assert_equal([], config[:options])
    assert_equal(
      Yard::Lint::Validators::Tags::Order::Config.defaults['EnforcedOrder'],
      config.validator_config('Tags/Order', 'EnforcedOrder')
    )
  end

  def test_returns_nil_for_non_existent_attributes
    config = Yard::Lint::Config.new

    assert_nil(config[:nonexistent])
  end

  def test_edge_cases_handles_invalid_severity_levels_gracefully
    config = Yard::Lint::Config.new do |c|
      c.fail_on_severity = 'invalid'
    end

    assert_equal('invalid', config.fail_on_severity)
  end

  def test_edge_cases_handles_empty_tags_order
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Tags/Order', 'EnforcedOrder', [])
    end

    assert_equal([], config.validator_config('Tags/Order', 'EnforcedOrder'))
  end

  def test_edge_cases_handles_nil_values_in_configuration
    config = Yard::Lint::Config.new({ 'AllValidators' => { 'Exclude' => nil } })

    assert_includes(config.exclude, '\.git')
    assert_includes(config.exclude, 'vendor/**/*')
    assert_includes(config.exclude, 'node_modules/**/*')
  end

  def test_edge_cases_returns_correct_validator_severity
    config = Yard::Lint::Config.new({ 'Tags/Order' => { 'Severity' => 'error' } })

    assert_equal('error', config.validator_severity('Tags/Order'))
  end

  def test_edge_cases_returns_department_severity_when_validator_severity_not_set
    config = Yard::Lint::Config.new

    assert_equal('convention', config.validator_severity('Tags/Order'))
  end

  def test_edge_cases_returns_validator_exclude_patterns
    config = Yard::Lint::Config.new({ 'Tags/Order' => { 'Exclude' => ['test/**/*'] } })

    assert_equal(['test/**/*'], config.validator_exclude('Tags/Order'))
  end

  def test_edge_cases_returns_empty_array_for_validator_without_exclude_patterns
    config = Yard::Lint::Config.new

    assert_equal([], config.validator_exclude('Tags/Order'))
  end

  def test_edge_cases_returns_validator_config_value
    config = Yard::Lint::Config.new({ 'Tags/Order' => { 'EnforcedOrder' => %w[param return] } })

    assert_equal(%w[param return], config.validator_config('Tags/Order', 'EnforcedOrder'))
  end

  def test_edge_cases_returns_nil_for_non_existent_validator_config_key
    config = Yard::Lint::Config.new

    assert_nil(config.validator_config('Tags/Order', 'NonExistent'))
  end

  def test_from_file_raises_configfilenotfounderror_for_non_existent_file
    error = assert_raises(Yard::Lint::Errors::ConfigFileNotFoundError) do
      Yard::Lint::Config.from_file('/non/existent/file.yml')
    end
    assert_match(/Config file not found/, error.message)
  end

  def test_only_validators_defaults_to_empty_array
    config = Yard::Lint::Config.new

    assert_equal([], config.only_validators)
  end

  def test_only_validators_can_be_set_to_a_list_of_validators
    config = Yard::Lint::Config.new
    config.only_validators = ['Tags/TypeSyntax', 'Tags/Order']

    assert_equal(['Tags/TypeSyntax', 'Tags/Order'], config.only_validators)
  end

  def test_validator_enabled_with_only_validators_returns_true_only_for_validators_in_the_only_list
    config = Yard::Lint::Config.new
    config.only_validators = ['Tags/TypeSyntax', 'Tags/Order']

    assert_equal(true, config.validator_enabled?('Tags/TypeSyntax'))
    assert_equal(true, config.validator_enabled?('Tags/Order'))
    assert_equal(false, config.validator_enabled?('Tags/InvalidTypes'))
    assert_equal(false, config.validator_enabled?('Documentation/UndocumentedObjects'))
  end

  def test_validator_enabled_with_only_validators_overrides_enabled_false_in_config
    config = Yard::Lint::Config.new({ 'Tags/TypeSyntax' => { 'Enabled' => false } })
    config.only_validators = ['Tags/TypeSyntax']

    assert_equal(true, config.validator_enabled?('Tags/TypeSyntax'))
  end

  def test_validator_enabled_with_only_validators_uses_normal_enabled_logic_when_empty
    config = Yard::Lint::Config.new({ 'Tags/TypeSyntax' => { 'Enabled' => false } })

    assert_equal(false, config.validator_enabled?('Tags/TypeSyntax'))
    assert_equal(true, config.validator_enabled?('Tags/Order'))
  end
end
