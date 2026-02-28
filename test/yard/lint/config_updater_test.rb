# frozen_string_literal: true

require 'test_helper'

class YardLintConfigUpdaterTest < Minitest::Test
  def setup
    @fixtures_dir = File.expand_path('../../fixtures', __dir__)
    @config_path = File.join(@fixtures_dir, '.yard-lint.yml')
    FileUtils.mkdir_p(@fixtures_dir)
  end

  def teardown
    FileUtils.rm_f(@config_path)
  end

  def test_update_when_config_file_does_not_exist_raises_configfilenotfounderror
    error = assert_raises(Yard::Lint::Errors::ConfigFileNotFoundError) do
      Yard::Lint::ConfigUpdater.update(path: @config_path)
    end
    assert_match(/Config file not found/, error.message)
  end

  def test_update_when_config_file_does_not_exist_suggests_using_init
    error = assert_raises(Yard::Lint::Errors::ConfigFileNotFoundError) do
      Yard::Lint::ConfigUpdater.update(path: @config_path)
    end
    assert_match(/Use --init to create one/, error.message)
  end

  def test_update_with_all_current_validators_present_reports_no_changes_needed
    template_path = File.join(Yard::Lint::ConfigUpdater::TEMPLATES_DIR, 'default_config.yml')
    FileUtils.cp(template_path, @config_path)

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_empty(result[:added])
    assert_empty(result[:removed])
  end

  def test_update_with_all_current_validators_present_returns_all_validators_as_preserved
    template_path = File.join(Yard::Lint::ConfigUpdater::TEMPLATES_DIR, 'default_config.yml')
    FileUtils.cp(template_path, @config_path)

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_equal(Yard::Lint::ConfigLoader::ALL_VALIDATORS.sort, result[:preserved])
  end

  def test_update_with_missing_validators_adds_new_validators_with_default_config
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'

      Documentation/UndocumentedObjects:
        Enabled: true
        Severity: error
    YAML

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_includes(result[:added], 'Tags/Order')
    assert_includes(result[:added], 'Tags/TypeSyntax')
  end

  def test_update_with_missing_validators_preserves_existing_validators
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'

      Documentation/UndocumentedObjects:
        Enabled: true
        Severity: error
    YAML

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_equal(['Documentation/UndocumentedObjects'], result[:preserved])
  end

  def test_update_with_missing_validators_preserves_user_settings_for_existing_validators
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'

      Documentation/UndocumentedObjects:
        Enabled: true
        Severity: error
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    updated = YAML.load_file(@config_path)
    assert_equal('error', updated['Documentation/UndocumentedObjects']['Severity'])
  end

  def test_update_with_missing_validators_writes_valid_yaml
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'

      Documentation/UndocumentedObjects:
        Enabled: true
        Severity: error
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    YAML.load_file(@config_path)
  end

  def test_update_with_obsolete_validators_removes_obsolete_validators
    template_path = File.join(Yard::Lint::ConfigUpdater::TEMPLATES_DIR, 'default_config.yml')
    template_content = File.read(template_path)
    obsolete_content = template_content + <<~YAML

      Obsolete/FakeValidator:
        Enabled: true
        Severity: warning
    YAML
    File.write(@config_path, obsolete_content)

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_equal(['Obsolete/FakeValidator'], result[:removed])
  end

  def test_update_with_obsolete_validators_does_not_include_obsolete_validators_in_output
    template_path = File.join(Yard::Lint::ConfigUpdater::TEMPLATES_DIR, 'default_config.yml')
    template_content = File.read(template_path)
    obsolete_content = template_content + <<~YAML

      Obsolete/FakeValidator:
        Enabled: true
        Severity: warning
    YAML
    File.write(@config_path, obsolete_content)

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    updated = YAML.load_file(@config_path)
    refute(updated.key?('Obsolete/FakeValidator'))
  end

  def test_update_with_partial_validator_config_merges_with_template_defaults
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []

      Tags/Order:
        Enabled: false
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    updated = YAML.load_file(@config_path)

    # User setting preserved
    assert_equal(false, updated['Tags/Order']['Enabled'])
    # Template default merged in
    assert_kind_of(Array, updated['Tags/Order']['EnforcedOrder'])
    assert_kind_of(String, updated['Tags/Order']['Description'])
  end

  def test_update_with_empty_config_file_adds_all_validators
    File.write(@config_path, '')

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_equal(Yard::Lint::ConfigLoader::ALL_VALIDATORS.size, result[:added].size)
    assert_empty(result[:preserved])
  end

  def test_update_with_strict_mode_uses_strict_template_defaults_for_new_validators
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []

      Documentation/UndocumentedObjects:
        Enabled: true
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path, strict: true)

    updated = YAML.load_file(@config_path)

    # New validators should use strict template
    assert_kind_of(Hash, updated['Tags/Order'])
  end

  def test_update_includes_header_comments
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    content = File.read(@config_path)
    assert_includes(content, '# YARD-Lint Configuration')
  end

  def test_update_includes_category_comments
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    content = File.read(@config_path)
    assert_includes(content, '# Documentation validators')
    assert_includes(content, '# Tags validators')
    assert_includes(content, '# Warnings validators')
    assert_includes(content, '# Semantic validators')
  end

  def test_update_groups_validators_by_category
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    content = File.read(@config_path)

    # Documentation validators should come before Tags validators
    doc_pos = content.index('Documentation/UndocumentedObjects:')
    tags_pos = content.index('Tags/Order:')
    assert_operator(doc_pos, :<, tags_pos)
  end

  def test_update_preserves_allvalidators_section
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    updated = YAML.load_file(@config_path)
    assert(updated.key?('AllValidators'))
  end

  def test_initialize_uses_default_path_when_none_provided
    Dir.chdir(@fixtures_dir) do
      File.write('.yard-lint.yml', 'AllValidators: {}')
      updater = Yard::Lint::ConfigUpdater.new
      updater.update
      File.delete('.yard-lint.yml')
    end
  end

  def test_initialize_uses_provided_path
    custom_path = File.join(@fixtures_dir, 'custom_config.yml')
    File.write(custom_path, 'AllValidators: {}')

    result = Yard::Lint::ConfigUpdater.update(path: custom_path)

    assert_kind_of(Hash, result)
  ensure
    FileUtils.rm_f(custom_path) if custom_path
  end
end
