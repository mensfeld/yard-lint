# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

describe 'Todo Check' do
  attr_reader :test_dir, :bin_path, :original_dir

  before do
    @original_dir = Dir.pwd
    @test_dir = Dir.mktmpdir('yard-lint-todo-check-test')
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

  def write_undocumented(path, class_name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "class #{class_name}\nend\n")
  end

  def write_documented(path, class_name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "# Documented #{class_name}\nclass #{class_name}\nend\n")
  end

  it 'passes right after the todo file is generated' do
    write_undocumented('lib/a.rb', 'A')
    write_undocumented('lib/b.rb', 'B')
    run_yard_lint('--auto-gen-config', 'lib')

    result = run_yard_lint('--check-todo', 'lib')

    assert_equal(0, result[:exit_code], result[:stdout])
    assert_includes(result[:stdout], 'No unused entries found')
  end

  it 'reports entries whose files no longer have offenses and exits non-zero' do
    write_undocumented('lib/a.rb', 'A')
    write_undocumented('lib/b.rb', 'B')
    run_yard_lint('--auto-gen-config', 'lib')
    write_documented('lib/a.rb', 'A')

    result = run_yard_lint('--check-todo', 'lib')

    assert_equal(1, result[:exit_code])
    assert_includes(result[:stdout], 'Documentation/UndocumentedObjects:')
    assert_includes(result[:stdout], "- 'lib/a.rb'")
    refute_includes(result[:stdout], "- 'lib/b.rb'")
  end

  it 'reports entries for files that no longer exist' do
    write_undocumented('lib/a.rb', 'A')
    write_undocumented('lib/b.rb', 'B')
    run_yard_lint('--auto-gen-config', 'lib')
    FileUtils.rm('lib/b.rb')

    result = run_yard_lint('--check-todo', 'lib')

    assert_equal(1, result[:exit_code])
    assert_includes(result[:stdout], "- 'lib/b.rb'")
  end

  it 'keeps a grouped pattern while any file under it still has offenses' do
    write_undocumented('lib/a.rb', 'A')
    write_undocumented('lib/b.rb', 'B')
    File.write('.yard-lint-todo.yml', <<~YAML)
      Documentation/UndocumentedObjects:
        Exclude:
          - 'lib/**/*'
          - 'app/**/*'
    YAML
    File.write('.yard-lint.yml', "inherit_from:\n  - .yard-lint-todo.yml\n")
    write_documented('lib/a.rb', 'A')

    result = run_yard_lint('--check-todo', 'lib')

    assert_equal(1, result[:exit_code])
    assert_includes(result[:stdout], "- 'app/**/*'")
    refute_includes(result[:stdout], "- 'lib/**/*'")
  end

  it 'does not report entries whose offenses lie outside the checked path' do
    write_undocumented('lib/a.rb', 'A')
    write_undocumented('lib/b.rb', 'B')
    write_undocumented('app/c.rb', 'C')
    File.write('.yard-lint-todo.yml', <<~YAML)
      Documentation/UndocumentedObjects:
        Exclude:
          - 'lib/a.rb'
          - 'lib/b.rb'
          - 'app/**/*'
    YAML
    File.write('.yard-lint.yml', "inherit_from:\n  - .yard-lint-todo.yml\n")

    result = run_yard_lint('--check-todo', 'lib/a.rb')

    assert_equal(0, result[:exit_code], result[:stdout])
    assert_includes(result[:stdout], 'No unused entries found')
  end

  it 'keeps an entry whose offense moves to another file when only part of the project is checked' do
    write_undocumented('lib/a.rb', 'Foo')
    write_undocumented('lib/b.rb', 'Foo')
    run_yard_lint('--auto-gen-config', 'lib')

    %w[lib/a.rb lib/b.rb lib].each do |path|
      result = run_yard_lint('--check-todo', path)

      assert_equal(0, result[:exit_code], "#{path}: #{result[:stdout]}")
      assert_includes(result[:stdout], 'No unused entries found')
    end
  end

  it 'keeps a cross-file validator entry when only part of the project is checked' do
    FileUtils.mkdir_p('lib')
    File.write('lib/a.rb', "# Doc one\nmodule Foo\nend\n")
    File.write('lib/b.rb', "# Doc two\nmodule Foo\nend\n")
    write_documented('lib/c.rb', 'C')
    File.write('.yard-lint-todo.yml', <<~YAML)
      Documentation/DuplicateNamespaceComment:
        Exclude:
          - 'lib/a.rb'
    YAML
    File.write('.yard-lint.yml', "inherit_from:\n  - .yard-lint-todo.yml\n")

    %w[lib/a.rb lib/b.rb lib/c.rb lib].each do |path|
      result = run_yard_lint('--check-todo', path)

      assert_equal(0, result[:exit_code], "#{path}: #{result[:stdout]}")
      assert_includes(result[:stdout], 'No unused entries found')
    end
  end

  it 'does not modify the todo file' do
    write_undocumented('lib/a.rb', 'A')
    run_yard_lint('--auto-gen-config', 'lib')
    write_documented('lib/a.rb', 'A')
    before = File.read('.yard-lint-todo.yml')

    run_yard_lint('--check-todo', 'lib')

    assert_equal(before, File.read('.yard-lint-todo.yml'))
  end

  it 'fails with a clear error when there is no todo file' do
    write_undocumented('lib/a.rb', 'A')

    result = run_yard_lint('--check-todo', 'lib')

    assert_equal(1, result[:exit_code])
    assert_includes(result[:stdout], '.yard-lint-todo.yml not found')
  end

  it 'returns unused entries from the API' do
    write_undocumented('lib/a.rb', 'A')
    File.write('.yard-lint-todo.yml', <<~YAML)
      Documentation/UndocumentedObjects:
        Exclude:
          - 'lib/a.rb'
          - 'lib/gone.rb'
    YAML
    config = Yard::Lint::Config.new(
      'Documentation/UndocumentedObjects' => { 'Exclude' => ['lib/a.rb', 'lib/gone.rb'] }
    )

    result = Yard::Lint::TodoGenerator.check(path: 'lib', config: config)

    assert_equal({ 'Documentation/UndocumentedObjects' => ['lib/gone.rb'] }, result[:unused_entries])
  end

  it 'does not modify the given config' do
    write_undocumented('lib/a.rb', 'A')
    File.write('.yard-lint-todo.yml', <<~YAML)
      Documentation/UndocumentedObjects:
        Exclude:
          - 'lib/a.rb'
    YAML
    config = Yard::Lint::Config.new(
      'Documentation/UndocumentedObjects' => { 'Exclude' => ['lib/a.rb'] }
    )

    Yard::Lint::TodoGenerator.check(path: 'lib', config: config)

    assert_equal(['lib/a.rb'], config.validator_exclude('Documentation/UndocumentedObjects'))
    assert_predicate(Yard::Lint.run(path: 'lib', config: config), :clean?)
  end

  it 'keeps the user Exclude when it replaces the todo list' do
    write_undocumented('lib/a.rb', 'A')
    write_undocumented('lib/b.rb', 'B')
    File.write('.yard-lint-todo.yml', <<~YAML)
      Documentation/UndocumentedObjects:
        Exclude:
          - 'lib/a.rb'
          - 'lib/b.rb'
    YAML
    File.write('.yard-lint.yml', <<~YAML)
      inherit_from:
        - .yard-lint-todo.yml
      Documentation/UndocumentedObjects:
        Exclude:
          - 'lib/a.rb'
    YAML

    result = run_yard_lint('--check-todo', 'lib')

    assert_equal(1, result[:exit_code])
    assert_includes(result[:stdout], "- 'lib/a.rb'")
    refute_includes(result[:stdout], "- 'lib/b.rb'")
  end

  it 'does not judge entries of validators left out by --only' do
    write_undocumented('lib/a.rb', 'A')
    File.write('.yard-lint-todo.yml', <<~YAML)
      Documentation/UndocumentedObjects:
        Exclude:
          - 'lib/a.rb'
      Tags/Order:
        Exclude:
          - 'lib/a.rb'
    YAML
    File.write('.yard-lint.yml', "inherit_from:\n  - .yard-lint-todo.yml\n")

    result = run_yard_lint('--check-todo', '--only', 'Documentation/UndocumentedObjects', 'lib')

    assert_equal(0, result[:exit_code], result[:stdout])
    assert_includes(result[:stdout], 'No unused entries found')

    write_documented('lib/a.rb', 'A')
    result = run_yard_lint('--check-todo', '--only', 'Documentation/UndocumentedObjects', 'lib')

    assert_equal(1, result[:exit_code])
    assert_includes(result[:stdout], 'Documentation/UndocumentedObjects:')
    refute_includes(result[:stdout], 'Tags/Order:')
  end

  it 'rejects unknown validators given to --only' do
    write_undocumented('lib/a.rb', 'A')
    run_yard_lint('--auto-gen-config', 'lib')

    result = run_yard_lint('--check-todo', '--only', 'Tags/Nope', 'lib')

    assert_equal(1, result[:exit_code])
    assert_includes(result[:stdout], 'Unknown validator(s)')
  end
end
