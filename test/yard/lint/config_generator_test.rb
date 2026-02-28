# frozen_string_literal: true

require 'test_helper'

class YardLintConfigGeneratorTest < Minitest::Test

  def setup
    @temp_dir = Dir.mktmpdir
    @config_path = File.join(@temp_dir, '.yard-lint.yml')
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  def test_creates_yard_lint_yml_file
    assert_equal(false, File.exist?(@config_path))

    result = Yard::Lint::ConfigGenerator.generate

    assert_equal(true, result)
    assert_equal(true, File.exist?(@config_path))
  end

  def test_creates_file_with_yard_lint_configuration_header
    Yard::Lint::ConfigGenerator.generate

    content = File.read(@config_path)
    assert_includes(content, '# YARD-Lint Configuration')
    assert_includes(content, '# See https://github.com/mensfeld/yard-lint for documentation')
  end

  def test_creates_file_with_allvalidators_section
    Yard::Lint::ConfigGenerator.generate

    content = File.read(@config_path)
    assert_includes(content, 'AllValidators:')
    assert_includes(content, 'YardOptions:')
    assert_includes(content, 'Exclude:')
    assert_includes(content, 'FailOnSeverity: warning')
  end

  def test_creates_file_with_all_discovered_validator_configurations
    Yard::Lint::ConfigGenerator.generate

    content = File.read(@config_path)

    # Dynamically check all validators from ConfigLoader
    Yard::Lint::ConfigLoader::ALL_VALIDATORS.each do |validator_name|
      assert_includes(content, "#{validator_name}:",
        "Expected config to include #{validator_name}")
        end
  end

  def test_creates_file_with_default_exclusions
    Yard::Lint::ConfigGenerator.generate

    content = File.read(@config_path)
    assert_includes(content, "- '\\.git'")
    assert_includes(content, "- 'vendor/**/*'")
    assert_includes(content, "- 'node_modules/**/*'")
    assert_includes(content, "- 'spec/**/*'")
    assert_includes(content, "- 'test/**/*'")
  end

  def test_creates_file_with_yard_options
    Yard::Lint::ConfigGenerator.generate

    content = File.read(@config_path)
    assert_includes(content, '- --private')
    assert_includes(content, '- --protected')
  end

  def test_when_config_file_already_exists_returns_false_without_overwriting
    File.write(@config_path, '# Existing config')

    result = Yard::Lint::ConfigGenerator.generate

    assert_equal(false, result)
    assert_equal('# Existing config', File.read(@config_path))
  end

  def test_when_config_file_already_exists_with_force_overwrites_existing_file
    File.write(@config_path, '# Existing config')

    result = Yard::Lint::ConfigGenerator.generate(force: true)

    assert_equal(true, result)
    content = File.read(@config_path)
    assert_includes(content, '# YARD-Lint Configuration')
    refute_equal('# Existing config', content)
  end

  def test_generates_valid_yaml
    Yard::Lint::ConfigGenerator.generate

    YAML.load_file(@config_path)
  end

  def test_generates_parseable_config
    Yard::Lint::ConfigGenerator.generate

    config_hash = YAML.load_file(@config_path)
    assert_kind_of(Hash, config_hash)
    assert(config_hash.key?('AllValidators'))
    assert(config_hash['AllValidators'].key?('YardOptions'))
    assert(config_hash['AllValidators'].key?('Exclude'))
    assert(config_hash['AllValidators'].key?('FailOnSeverity'))
  end
end
