# frozen_string_literal: true

require 'test_helper'

require 'tmpdir'

describe 'Yard::Lint::Config' do
  it 'initialize sets default values' do
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

  it 'initialize accepts a block for configuration' do
    config = Yard::Lint::Config.new do |c|
      c.options = ['--private']
      c.set_validator_config('Tags/Order', 'EnforcedOrder', %w[param return])
      c.set_validator_config('Tags/InvalidTypes', 'ExtraTypes', ['CustomType'])
      c.exclude = ['spec/**/*']
      c.fail_on_severity = 'error'
      c.set_validator_config('Tags/ApiTags', 'Enabled', true)
      c.set_validator_config('Tags/ApiTags', 'AllowedApis', %w[public private])
      c.set_validator_config('Semantic/AbstractMethods', 'Enabled', true)
      c.set_validator_config('Tags/OptionTags', 'Enabled', true)
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

  it 'from file raises an error if file does not exist' do
    error = assert_raises(Yard::Lint::Errors::ConfigFileNotFoundError) do
      Yard::Lint::Config.from_file('/nonexistent/file.yml')
    end
    assert_match(/Config file not found/, error.message)
  end

  it 'from file loads configuration from yaml file' do
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

  it 'from file uses defaults for missing keys' do
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

  it 'load returns nil if no config file is found' do
    Yard::Lint::Config.stubs(:find_config_file).returns(nil)

    assert_nil(Yard::Lint::Config.load)
  end

  it 'load loads config file if found' do
    config_path = '/tmp/.yard-lint.yml'
    Yard::Lint::Config.stubs(:find_config_file).returns(config_path)
    File.stubs(:exist?).with(config_path).returns(true)
    YAML.stubs(:load_file).with(config_path).returns({})

    config = Yard::Lint::Config.load

    assert_kind_of(Yard::Lint::Config, config)
  end

  it 'find config file finds config file in current directory' do
    Dir.mktmpdir do |dir|
      config_file = File.join(dir, Yard::Lint::Config::DEFAULT_CONFIG_FILE)
      File.write(config_file, '')

      assert_equal(config_file, Yard::Lint::Config.find_config_file(dir))
    end
  end

  it 'find config file finds config file in parent directory' do
    Dir.mktmpdir do |parent_dir|
      config_file = File.join(parent_dir, Yard::Lint::Config::DEFAULT_CONFIG_FILE)
      File.write(config_file, '')

      child_dir = File.join(parent_dir, 'child')
      Dir.mkdir(child_dir)

      assert_equal(config_file, Yard::Lint::Config.find_config_file(child_dir))
    end
  end

  it 'find config file returns nil if no config file is found' do
    Dir.mktmpdir do |dir|
      assert_nil(Yard::Lint::Config.find_config_file(dir))
    end
  end

  it 'allows hash like access to attributes' do
    config = Yard::Lint::Config.new

    assert_equal([], config[:options])
    assert_equal(
      Yard::Lint::Validators::Tags::Order::Config.defaults['EnforcedOrder'],
      config.validator_config('Tags/Order', 'EnforcedOrder')
    )
  end

  it 'returns nil for non existent attributes' do
    config = Yard::Lint::Config.new

    assert_nil(config[:nonexistent])
  end

  it 'edge cases handles invalid severity levels gracefully' do
    config = Yard::Lint::Config.new do |c|
      c.fail_on_severity = 'invalid'
    end

    assert_equal('invalid', config.fail_on_severity)
  end

  it 'edge cases handles empty tags order' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Tags/Order', 'EnforcedOrder', [])
    end

    assert_equal([], config.validator_config('Tags/Order', 'EnforcedOrder'))
  end

  it 'edge cases handles nil values in configuration' do
    config = Yard::Lint::Config.new({ 'AllValidators' => { 'Exclude' => nil } })

    assert_includes(config.exclude, '\.git')
    assert_includes(config.exclude, 'vendor/**/*')
    assert_includes(config.exclude, 'node_modules/**/*')
  end

  it 'edge cases returns correct validator severity' do
    config = Yard::Lint::Config.new({ 'Tags/Order' => { 'Severity' => 'error' } })

    assert_equal('error', config.validator_severity('Tags/Order'))
  end

  it 'edge cases returns department severity when validator severity not set' do
    config = Yard::Lint::Config.new

    assert_equal('convention', config.validator_severity('Tags/Order'))
  end

  it 'edge cases returns validator exclude patterns' do
    config = Yard::Lint::Config.new({ 'Tags/Order' => { 'Exclude' => ['test/**/*'] } })

    assert_equal(['test/**/*'], config.validator_exclude('Tags/Order'))
  end

  it 'edge cases returns empty array for validator without exclude patterns' do
    config = Yard::Lint::Config.new

    assert_equal([], config.validator_exclude('Tags/Order'))
  end

  it 'edge cases returns validator config value' do
    config = Yard::Lint::Config.new({ 'Tags/Order' => { 'EnforcedOrder' => %w[param return] } })

    assert_equal(%w[param return], config.validator_config('Tags/Order', 'EnforcedOrder'))
  end

  it 'edge cases returns nil for non existent validator config key' do
    config = Yard::Lint::Config.new

    assert_nil(config.validator_config('Tags/Order', 'NonExistent'))
  end

  it 'from file raises configfilenotfounderror for non existent file' do
    error = assert_raises(Yard::Lint::Errors::ConfigFileNotFoundError) do
      Yard::Lint::Config.from_file('/non/existent/file.yml')
    end
    assert_match(/Config file not found/, error.message)
  end

  it 'only validators defaults to empty array' do
    config = Yard::Lint::Config.new

    assert_equal([], config.only_validators)
  end

  it 'only validators can be set to a list of validators' do
    config = Yard::Lint::Config.new
    config.only_validators = ['Tags/TypeSyntax', 'Tags/Order']

    assert_equal(['Tags/TypeSyntax', 'Tags/Order'], config.only_validators)
  end

  it 'validator enabled with only validators returns true only for validators in the only list' do
    config = Yard::Lint::Config.new
    config.only_validators = ['Tags/TypeSyntax', 'Tags/Order']

    assert_equal(true, config.validator_enabled?('Tags/TypeSyntax'))
    assert_equal(true, config.validator_enabled?('Tags/Order'))
    assert_equal(false, config.validator_enabled?('Tags/InvalidTypes'))
    assert_equal(false, config.validator_enabled?('Documentation/UndocumentedObjects'))
  end

  it 'validator enabled with only validators overrides enabled false in config' do
    config = Yard::Lint::Config.new({ 'Tags/TypeSyntax' => { 'Enabled' => false } })
    config.only_validators = ['Tags/TypeSyntax']

    assert_equal(true, config.validator_enabled?('Tags/TypeSyntax'))
  end

  it 'validator enabled with only validators uses normal enabled logic when empty' do
    config = Yard::Lint::Config.new({ 'Tags/TypeSyntax' => { 'Enabled' => false } })

    assert_equal(false, config.validator_enabled?('Tags/TypeSyntax'))
    assert_equal(true, config.validator_enabled?('Tags/Order'))
  end
end
