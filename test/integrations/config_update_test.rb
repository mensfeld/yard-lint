# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'
require 'test_helper'

class ConfigUpdateIntegrationTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
    Dir.chdir(@test_dir)
  end

  def teardown
    Dir.chdir('/')
    FileUtils.rm_rf(@test_dir)
  end

  def run_yard_lint(*args)
    stdout, stderr, status = Open3.capture3(@bin_path, *args)
    { stdout: stdout, stderr: stderr, exit_code: status.exitstatus }
  end

  # -- update when config file does not exist --

  def test_update_when_config_does_not_exist_exits_with_error_code_1
    result = run_yard_lint('--update')

    assert_equal(1, result[:exit_code])
  end

  def test_update_when_config_does_not_exist_displays_helpful_error_message
    result = run_yard_lint('--update')

    assert_includes(result[:stdout], 'Config file not found')
    assert_includes(result[:stdout], 'Use --init to create one')
  end

  # -- update when config file exists and is up to date --

  def test_update_when_config_exists_and_is_up_to_date_exits_with_success_code_0
    run_yard_lint('--init')
    result = run_yard_lint('--update')

    assert_equal(0, result[:exit_code])
  end

  def test_update_when_config_exists_and_is_up_to_date_reports_config_is_up_to_date
    run_yard_lint('--init')
    result = run_yard_lint('--update')

    assert_includes(result[:stdout], 'already up to date')
  end

  # -- update when config file is missing validators --

  def write_partial_config
    File.write('.yard-lint.yml', <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'

      Documentation/UndocumentedObjects:
        Enabled: true
        Severity: error
    YAML
  end

  def test_update_when_missing_validators_exits_with_success_code_0
    write_partial_config
    result = run_yard_lint('--update')

    assert_equal(0, result[:exit_code])
  end

  def test_update_when_missing_validators_reports_added_validators
    write_partial_config
    result = run_yard_lint('--update')

    assert_includes(result[:stdout], 'Updated .yard-lint.yml')
    assert_includes(result[:stdout], 'Added')
    assert_includes(result[:stdout], 'new validator')
  end

  def test_update_when_missing_validators_reports_preserved_validators
    write_partial_config
    result = run_yard_lint('--update')

    assert_includes(result[:stdout], 'Preserved 1 existing validator')
  end

  def test_update_when_missing_validators_preserves_user_settings_in_the_file
    write_partial_config
    run_yard_lint('--update')

    updated_config = YAML.load_file('.yard-lint.yml')
    assert_equal('error', updated_config['Documentation/UndocumentedObjects']['Severity'])
  end

  def test_update_when_missing_validators_adds_missing_validators_to_the_file
    write_partial_config
    run_yard_lint('--update')

    updated_config = YAML.load_file('.yard-lint.yml')
    assert(updated_config.key?('Tags/Order'))
    assert(updated_config.key?('Tags/TypeSyntax'))
    assert(updated_config.key?('Warnings/UnknownTag'))
  end

  def test_update_when_missing_validators_produces_valid_yaml
    write_partial_config
    run_yard_lint('--update')

    YAML.load_file('.yard-lint.yml')
  end

  # -- update when config file has obsolete validators --

  def write_config_with_obsolete_validator
    run_yard_lint('--init')

    content = File.read('.yard-lint.yml')
    content += <<~YAML

      Obsolete/FakeValidator:
        Enabled: true
        Severity: warning
    YAML
    File.write('.yard-lint.yml', content)
  end

  def test_update_when_obsolete_validators_reports_removed_validators
    write_config_with_obsolete_validator
    result = run_yard_lint('--update')

    assert_includes(result[:stdout], 'Removed')
    assert_includes(result[:stdout], 'Obsolete/FakeValidator')
  end

  def test_update_when_obsolete_validators_removes_obsolete_validators_from_the_file
    write_config_with_obsolete_validator
    run_yard_lint('--update')

    updated_config = YAML.load_file('.yard-lint.yml')
    refute(updated_config.key?('Obsolete/FakeValidator'))
  end

  # -- update with --strict flag --

  def test_update_with_strict_flag_uses_strict_template_defaults_for_new_validators
    File.write('.yard-lint.yml', <<~YAML)
      AllValidators:
        Exclude: []

      Documentation/UndocumentedObjects:
        Enabled: true
    YAML

    run_yard_lint('--update', '--strict')

    updated_config = YAML.load_file('.yard-lint.yml')

    # Check that new validators were added
    assert(updated_config.key?('Tags/Order'))
  end

  # -- YAML output formatting --

  def write_minimal_config
    File.write('.yard-lint.yml', 'AllValidators: {}')
  end

  def test_update_yaml_formatting_includes_header_comment
    write_minimal_config
    run_yard_lint('--update')

    content = File.read('.yard-lint.yml')
    assert_includes(content, '# YARD-Lint Configuration')
  end

  def test_update_yaml_formatting_includes_category_comments
    write_minimal_config
    run_yard_lint('--update')

    content = File.read('.yard-lint.yml')
    assert_includes(content, '# Documentation validators')
    assert_includes(content, '# Tags validators')
    assert_includes(content, '# Warnings validators')
    assert_includes(content, '# Semantic validators')
  end

  def test_update_yaml_formatting_maintains_proper_category_ordering
    write_minimal_config
    run_yard_lint('--update')

    content = File.read('.yard-lint.yml')

    # Documentation should come before Tags
    doc_pos = content.index('# Documentation validators')
    tags_pos = content.index('# Tags validators')
    warnings_pos = content.index('# Warnings validators')
    semantic_pos = content.index('# Semantic validators')

    assert_operator(doc_pos, :<, tags_pos)
    assert_operator(tags_pos, :<, warnings_pos)
    assert_operator(warnings_pos, :<, semantic_pos)
  end

  # -- help --

  def test_help_includes_update_in_the_help_text
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], '--update')
    assert_includes(result[:stdout], 'add new validators')
  end

  def test_help_includes_update_in_the_examples
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], 'yard-lint --update')
  end

  # -- workflow: init then update --

  def test_workflow_init_then_update_works_correctly
    init_result = run_yard_lint('--init')
    assert_equal(0, init_result[:exit_code])

    update_result = run_yard_lint('--update')
    assert_equal(0, update_result[:exit_code])
    assert_includes(update_result[:stdout], 'already up to date')
  end
end
