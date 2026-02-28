# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'
require 'test_helper'

class TodoGenerationIntegrationTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir('yard-lint-todo-test')
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

  def create_file_with_violations
    FileUtils.mkdir_p('lib')
    File.write('lib/example.rb', <<~RUBY)
      class Example
        def method_without_docs(param)
        end
      end
    RUBY
  end

  def create_multiple_files_with_violations
    FileUtils.mkdir_p('lib')
    5.times do |i|
      File.write("lib/file_#{i}.rb", <<~RUBY)
        class File#{i}
          def undocumented_method(arg)
          end
        end
      RUBY
      end
  end

  def create_clean_file
    FileUtils.mkdir_p('lib')
    File.write('lib/clean.rb', <<~RUBY)
      # Documentation for Clean
      class Clean
      end
    RUBY
  end

  # -- auto-gen-config with violations --

  def test_auto_gen_config_with_violations_creates_yard_lint_todo_yml
    create_file_with_violations
    result = run_yard_lint('--auto-gen-config')

    assert_equal(0, result[:exit_code])
    assert(File.exist?('.yard-lint-todo.yml'))
  end

  def test_auto_gen_config_with_violations_displays_success_message
    create_file_with_violations
    result = run_yard_lint('--auto-gen-config')

    assert_includes(result[:stdout], 'Created .yard-lint-todo.yml')
    assert_includes(result[:stdout], 'Silenced')
    assert_includes(result[:stdout], 'offense(s)')
  end

  def test_auto_gen_config_with_violations_creates_valid_yaml_with_proper_structure
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    YAML.load_file('.yard-lint-todo.yml')

    content = File.read('.yard-lint-todo.yml')
    assert_includes(content, '# This file was auto-generated')
    assert_includes(content, '# To gradually fix violations')
    assert_includes(content, 'Exclude:')
  end

  def test_auto_gen_config_with_violations_includes_validator_exclusions
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    yaml = YAML.load_file('.yard-lint-todo.yml')

    # Should have at least one validator with Exclude list
    assert_operator(yaml.keys.size, :>, 0)

    yaml.each do |validator_name, config|
      assert_includes(validator_name, '/')
      assert(config.key?('Exclude'))
      assert_kind_of(Array, config['Exclude'])
      end
  end

  def test_auto_gen_config_with_violations_creates_or_updates_yard_lint_yml_to_inherit_from_todo_file
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    assert(File.exist?('.yard-lint.yml'))

    config = YAML.load_file('.yard-lint.yml')
    assert_includes(config['inherit_from'], '.yard-lint-todo.yml')
  end

  def test_auto_gen_config_with_violations_uses_relative_paths_in_exclusions
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    yaml = YAML.load_file('.yard-lint-todo.yml')

    yaml.each_value do |config|
      config['Exclude'].each do |pattern|
        # Should not contain absolute paths
        refute(pattern.start_with?('/'))
        refute_includes(pattern, @test_dir)
        end
    end
  end

  def test_auto_gen_config_with_violations_results_in_clean_run_after_generation
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    # Run yard-lint again
    result = run_yard_lint('lib/')

    assert_equal(0, result[:exit_code])
    assert_includes(result[:stdout], 'No offenses found')
  end

  # -- auto-gen-config with clean codebase --

  def test_auto_gen_config_with_clean_codebase_does_not_create_todo_file
    create_clean_file
    result = run_yard_lint('--auto-gen-config')

    assert_equal(0, result[:exit_code])
    refute(File.exist?('.yard-lint-todo.yml'))
  end

  def test_auto_gen_config_with_clean_codebase_displays_appropriate_message
    create_clean_file
    result = run_yard_lint('--auto-gen-config')

    assert_includes(result[:stdout], 'No offenses found')
    assert_includes(result[:stdout], 'already compliant')
  end

  # -- auto-gen-config when todo file already exists --

  def test_auto_gen_config_when_todo_already_exists_exits_with_error_code_1
    create_file_with_violations
    File.write('.yard-lint-todo.yml', '# existing content')

    result = run_yard_lint('--auto-gen-config')

    assert_equal(1, result[:exit_code])
  end

  def test_auto_gen_config_when_todo_already_exists_displays_error_message
    create_file_with_violations
    File.write('.yard-lint-todo.yml', '# existing content')

    result = run_yard_lint('--auto-gen-config')

    assert_includes(result[:stdout], 'Error')
    assert_includes(result[:stdout], '.yard-lint-todo.yml already exists')
    assert_includes(result[:stdout], '--regenerate-todo')
  end

  def test_auto_gen_config_when_todo_already_exists_does_not_overwrite_existing_file
    create_file_with_violations
    File.write('.yard-lint-todo.yml', '# existing content')

    run_yard_lint('--auto-gen-config')

    content = File.read('.yard-lint-todo.yml')
    assert_equal('# existing content', content)
  end

  # -- auto-gen-config when .yard-lint.yml already exists --

  def test_auto_gen_config_adds_inherit_from_to_existing_config
    create_file_with_violations
    File.write('.yard-lint.yml', <<~YAML)
      AllValidators:
        Severity: warning
    YAML

    run_yard_lint('--auto-gen-config')

    config = YAML.load_file('.yard-lint.yml')
    assert_includes(config['inherit_from'], '.yard-lint-todo.yml')
    assert_equal({ 'Severity' => 'warning' }, config['AllValidators'])
  end

  def test_auto_gen_config_does_not_duplicate_inherit_from_entry_on_multiple_runs
    create_file_with_violations
    File.write('.yard-lint.yml', <<~YAML)
      AllValidators:
        Severity: warning
    YAML

    run_yard_lint('--auto-gen-config')
    File.delete('.yard-lint-todo.yml')
    run_yard_lint('--auto-gen-config')

    config = YAML.load_file('.yard-lint.yml')
    count = config['inherit_from'].count('.yard-lint-todo.yml')
    assert_equal(1, count)
  end

  # -- auto-gen-config with multiple violations across validators --

  def test_auto_gen_config_with_multiple_violations_creates_separate_exclusions_for_each_validator
    FileUtils.mkdir_p('lib')
    File.write('lib/multi.rb', <<~RUBY)
      class Multi
        # @param invalid_name
        def foo(real_param)
        end
        def undocumented

        end
      end
    RUBY

    run_yard_lint('--auto-gen-config')

    yaml = YAML.load_file('.yard-lint-todo.yml')

    # Should have multiple validators
    assert_operator(yaml.keys.size, :>, 1)
  end

  def test_auto_gen_config_with_multiple_violations_groups_validators_by_category
    FileUtils.mkdir_p('lib')
    File.write('lib/multi.rb', <<~RUBY)
      class Multi
        # @param invalid_name
        def foo(real_param)
        end
        def undocumented

        end
      end
    RUBY

    run_yard_lint('--auto-gen-config')

    content = File.read('.yard-lint-todo.yml')

    # Should have category comments
    assert_includes(content, '# Documentation validators')
  end

  # -- auto-gen-config with path argument --

  def test_auto_gen_config_with_path_argument_generates_todo_file_for_specified_path_only
    FileUtils.mkdir_p('lib')
    FileUtils.mkdir_p('app')

    File.write('lib/test.rb', <<~RUBY)
      class Test
      end
    RUBY

    File.write('app/other.rb', <<~RUBY)
      class Other
      end
    RUBY

    result = run_yard_lint('--auto-gen-config', 'lib/')

    assert_equal(0, result[:exit_code])
    assert(File.exist?('.yard-lint-todo.yml'))
  end

  # -- regenerate-todo --

  def test_regenerate_todo_overwrites_existing_todo_file
    create_file_with_violations
    File.write('.yard-lint-todo.yml', '# existing content')

    result = run_yard_lint('--regenerate-todo')

    assert_equal(0, result[:exit_code])
    content = File.read('.yard-lint-todo.yml')
    refute_equal('# existing content', content)
    assert_includes(content, '# This file was auto-generated')
  end

  def test_regenerate_todo_displays_success_message
    create_file_with_violations
    File.write('.yard-lint-todo.yml', '# existing content')

    result = run_yard_lint('--regenerate-todo')

    assert_includes(result[:stdout], 'Created .yard-lint-todo.yml')
  end

  # -- exclude-limit --

  def test_exclude_limit_accepts_custom_exclude_limit
    create_multiple_files_with_violations
    result = run_yard_lint('--auto-gen-config', '--exclude-limit', '3')

    assert_equal(0, result[:exit_code])
    assert(File.exist?('.yard-lint-todo.yml'))
  end

  def test_exclude_limit_affects_grouping_behavior
    create_multiple_files_with_violations
    # With high limit, should keep individual files
    run_yard_lint('--auto-gen-config', '--exclude-limit', '100')

    yaml = YAML.load_file('.yard-lint-todo.yml')
    all_patterns = yaml.values.flat_map { |v| v['Exclude'] }

    # Should have individual files, not patterns
    assert(all_patterns.any? { |p| p.include?('file_0.rb') })
  end

  # -- help --

  def test_help_includes_auto_gen_config_in_the_help_text
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], '--auto-gen-config')
    assert_includes(result[:stdout], 'silence existing violations')
  end

  def test_help_includes_regenerate_todo_in_the_help_text
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], '--regenerate-todo')
  end

  def test_help_includes_exclude_limit_in_the_help_text
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], '--exclude-limit')
  end

  def test_help_includes_examples_in_the_help_text
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], 'yard-lint --auto-gen-config')
    assert_includes(result[:stdout], 'yard-lint --regenerate-todo')
  end

  # -- incremental workflow --

  def test_incremental_workflow_allows_removing_entries_to_re_expose_violations
    create_file_with_violations

    # Generate todo file
    run_yard_lint('--auto-gen-config')

    # Verify clean run
    result = run_yard_lint('lib/')
    assert_includes(result[:stdout], 'No offenses found')

    # Remove an entry from todo file
    yaml = YAML.load_file('.yard-lint-todo.yml')
    first_validator = yaml.keys.first
    yaml[first_validator]['Exclude'] = []
    File.write('.yard-lint-todo.yml', yaml.to_yaml)

    # Run again - should now show violations
    result = run_yard_lint('lib/')
    refute_equal(0, result[:exit_code])
    assert_includes(result[:stdout], 'offense(s)')
  end

  # -- YAML formatting --

  def test_yaml_formatting_includes_header_with_generation_timestamp
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    content = File.read('.yard-lint-todo.yml')
    assert_match(/# This file was auto-generated by yard-lint --auto-gen-config on \d{4}-\d{2}-\d{2}/, content)
  end

  def test_yaml_formatting_includes_helpful_comments
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    content = File.read('.yard-lint-todo.yml')
    assert_includes(content, 'To gradually fix violations')
    assert_includes(content, 'yard-lint --regenerate-todo')
  end

  def test_yaml_formatting_maintains_proper_category_ordering
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    content = File.read('.yard-lint-todo.yml')

    # Find positions of validators
    doc_validators = content.scan(/^Documentation\/\w+:/)
    tags_validators = content.scan(/^Tags\/\w+:/)

    # If both exist, Documentation should come before Tags
    if doc_validators.any? && tags_validators.any?
      doc_pos = content.index(doc_validators.first)
      tags_pos = content.index(tags_validators.first)
      assert_operator(doc_pos, :<, tags_pos)
      end
  end

  # -- error handling --

  def test_error_handling_handles_non_existent_paths_gracefully
    result = run_yard_lint('--auto-gen-config', 'non_existent/')

    assert_equal(1, result[:exit_code])
    assert_includes(result[:stdout], 'Error')
  end
end
