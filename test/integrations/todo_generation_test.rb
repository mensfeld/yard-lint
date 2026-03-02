# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

describe 'Todo Generation' do
  attr_reader :test_dir, :bin_path, :original_dir

  before do
    @original_dir = Dir.pwd
    @test_dir = Dir.mktmpdir('yard-lint-todo-test')
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
    Dir.chdir(@test_dir)
  end

  after do
    Dir.chdir(@original_dir)
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

  it 'auto gen config with violations creates yard lint todo yml' do
    create_file_with_violations
    result = run_yard_lint('--auto-gen-config')

    assert_equal(0, result[:exit_code])
    assert(File.exist?('.yard-lint-todo.yml'))
  end

  it 'auto gen config with violations displays success message' do
    create_file_with_violations
    result = run_yard_lint('--auto-gen-config')

    assert_includes(result[:stdout], 'Created .yard-lint-todo.yml')
    assert_includes(result[:stdout], 'Silenced')
    assert_includes(result[:stdout], 'offense(s)')
  end

  it 'auto gen config with violations creates valid yaml with proper structure' do
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    YAML.load_file('.yard-lint-todo.yml')

    content = File.read('.yard-lint-todo.yml')
    assert_includes(content, '# This file was auto-generated')
    assert_includes(content, '# To gradually fix violations')
    assert_includes(content, 'Exclude:')
  end

  it 'auto gen config with violations includes validator exclusions' do
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

  it 'auto gen config with violations creates or updates yard lint yml to inherit from todo file' do
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    assert(File.exist?('.yard-lint.yml'))

    config = YAML.load_file('.yard-lint.yml')
    assert_includes(config['inherit_from'], '.yard-lint-todo.yml')
  end

  it 'auto gen config with violations uses relative paths in exclusions' do
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

  it 'auto gen config with violations results in clean run after generation' do
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    # Run yard-lint again
    result = run_yard_lint('lib/')

    assert_equal(0, result[:exit_code])
    assert_includes(result[:stdout], 'No offenses found')
  end

  # -- auto-gen-config with clean codebase --

  it 'auto gen config with clean codebase does not create todo file' do
    create_clean_file
    result = run_yard_lint('--auto-gen-config')

    assert_equal(0, result[:exit_code])
    refute(File.exist?('.yard-lint-todo.yml'))
  end

  it 'auto gen config with clean codebase displays appropriate message' do
    create_clean_file
    result = run_yard_lint('--auto-gen-config')

    assert_includes(result[:stdout], 'No offenses found')
    assert_includes(result[:stdout], 'already compliant')
  end

  # -- auto-gen-config when todo file already exists --

  it 'auto gen config when todo already exists exits with error code 1' do
    create_file_with_violations
    File.write('.yard-lint-todo.yml', '# existing content')

    result = run_yard_lint('--auto-gen-config')

    assert_equal(1, result[:exit_code])
  end

  it 'auto gen config when todo already exists displays error message' do
    create_file_with_violations
    File.write('.yard-lint-todo.yml', '# existing content')

    result = run_yard_lint('--auto-gen-config')

    assert_includes(result[:stdout], 'Error')
    assert_includes(result[:stdout], '.yard-lint-todo.yml already exists')
    assert_includes(result[:stdout], '--regenerate-todo')
  end

  it 'auto gen config when todo already exists does not overwrite existing file' do
    create_file_with_violations
    File.write('.yard-lint-todo.yml', '# existing content')

    run_yard_lint('--auto-gen-config')

    content = File.read('.yard-lint-todo.yml')
    assert_equal('# existing content', content)
  end

  # -- auto-gen-config when .yard-lint.yml already exists --

  it 'auto gen config adds inherit from to existing config' do
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

  it 'auto gen config does not duplicate inherit from entry on multiple runs' do
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

  it 'auto gen config with multiple violations creates separate exclusions for each validator' do
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

  it 'auto gen config with multiple violations groups validators by category' do
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

  it 'auto gen config with path argument generates todo file for specified path only' do
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

  it 'regenerate todo overwrites existing todo file' do
    create_file_with_violations
    File.write('.yard-lint-todo.yml', '# existing content')

    result = run_yard_lint('--regenerate-todo')

    assert_equal(0, result[:exit_code])
    content = File.read('.yard-lint-todo.yml')
    refute_equal('# existing content', content)
    assert_includes(content, '# This file was auto-generated')
  end

  it 'regenerate todo displays success message' do
    create_file_with_violations
    File.write('.yard-lint-todo.yml', '# existing content')

    result = run_yard_lint('--regenerate-todo')

    assert_includes(result[:stdout], 'Created .yard-lint-todo.yml')
  end

  # -- exclude-limit --

  it 'exclude limit accepts custom exclude limit' do
    create_multiple_files_with_violations
    result = run_yard_lint('--auto-gen-config', '--exclude-limit', '3')

    assert_equal(0, result[:exit_code])
    assert(File.exist?('.yard-lint-todo.yml'))
  end

  it 'exclude limit affects grouping behavior' do
    create_multiple_files_with_violations
    # With high limit, should keep individual files
    run_yard_lint('--auto-gen-config', '--exclude-limit', '100')

    yaml = YAML.load_file('.yard-lint-todo.yml')
    all_patterns = yaml.values.flat_map { |v| v['Exclude'] }

    # Should have individual files, not patterns
    assert(all_patterns.any? { |p| p.include?('file_0.rb') })
  end

  # -- help --

  it 'help includes auto gen config in the help text' do
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], '--auto-gen-config')
    assert_includes(result[:stdout], 'silence existing violations')
  end

  it 'help includes regenerate todo in the help text' do
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], '--regenerate-todo')
  end

  it 'help includes exclude limit in the help text' do
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], '--exclude-limit')
  end

  it 'help includes examples in the help text' do
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], 'yard-lint --auto-gen-config')
    assert_includes(result[:stdout], 'yard-lint --regenerate-todo')
  end

  # -- incremental workflow --

  it 'incremental workflow allows removing entries to re expose violations' do
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

  it 'yaml formatting includes header with generation timestamp' do
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    content = File.read('.yard-lint-todo.yml')
    assert_match(/# This file was auto-generated by yard-lint --auto-gen-config on \d{4}-\d{2}-\d{2}/, content)
  end

  it 'yaml formatting includes helpful comments' do
    create_file_with_violations
    run_yard_lint('--auto-gen-config')

    content = File.read('.yard-lint-todo.yml')
    assert_includes(content, 'To gradually fix violations')
    assert_includes(content, 'yard-lint --regenerate-todo')
  end

  it 'yaml formatting maintains proper category ordering' do
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

  it 'error handling handles non existent paths gracefully' do
    result = run_yard_lint('--auto-gen-config', 'non_existent/')

    assert_equal(1, result[:exit_code])
    assert_includes(result[:stdout], 'Error')
  end
end

