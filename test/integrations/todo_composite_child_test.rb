# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

# Proves that the todo file keys a composite child's offenses by the child.
# --auto-gen-config wrote Documentation/UndocumentedBooleanMethods offenses under
# Documentation/UndocumentedObjects, and --check-todo reported a child entry that
# silences a real offense as unused.
describe 'Todo file with a composite child validator' do
  attr_reader :project_dir, :bin_path

  before do
    @project_dir = Dir.mktmpdir('yard-lint-todo-composite-child-test')
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)

    FileUtils.mkdir_p(File.join(project_dir, 'lib'))
    write_class('Is it supervised')
  end

  after do
    FileUtils.rm_rf(project_dir)
  end

  def write_class(method_doc)
    File.write(File.join(project_dir, 'lib', 'q.rb'), <<~RUBY)
      # Doc.
      class Q
        # #{method_doc}
        def supervised?
          true
        end
      end
    RUBY
  end

  def write_todo(validator_name)
    File.write(
      File.join(project_dir, '.yard-lint-todo.yml'),
      "#{validator_name}:\n  Exclude:\n    - 'lib/q.rb'\n"
    )
    File.write(File.join(project_dir, '.yard-lint.yml'), "inherit_from:\n  - .yard-lint-todo.yml\n")
  end

  def run_yard_lint(*args)
    stdout, stderr, status = Open3.capture3(
      bin_path, '--no-progress', '--min-coverage', '0', *args, chdir: project_dir
    )
    { output: stdout + stderr, exit_code: status.exitstatus }
  end

  it 'files the child offense under the child with --auto-gen-config' do
    result = run_yard_lint('--auto-gen-config', 'lib')
    todo = YAML.load_file(File.join(project_dir, '.yard-lint-todo.yml'))

    assert_equal(0, result[:exit_code], result[:output])
    assert_equal({ 'Documentation/UndocumentedBooleanMethods' => { 'Exclude' => ['lib/q.rb'] } }, todo)
    assert_equal(0, run_yard_lint('lib')[:exit_code])
  end

  it 'leaves out a child offense the parent Exclude filters with --auto-gen-config' do
    File.write(
      File.join(project_dir, '.yard-lint.yml'),
      "Documentation/UndocumentedObjects:\n  Exclude:\n    - 'lib/q.rb'\n"
    )

    result = run_yard_lint('--auto-gen-config', 'lib')

    assert_equal(0, result[:exit_code], result[:output])
    assert_includes(result[:output], 'No offenses found')
    refute(File.exist?(File.join(project_dir, '.yard-lint-todo.yml')))
  end

  it 'counts a child entry that silences an offense as used' do
    write_todo('Documentation/UndocumentedBooleanMethods')

    assert_equal(0, run_yard_lint('lib')[:exit_code])

    result = run_yard_lint('--check-todo', 'lib')

    assert_equal(0, result[:exit_code], result[:output])
    assert_includes(result[:output], 'No unused entries found')
  end

  it 'reports a child entry as unused when the child has no offense' do
    write_class("Is it supervised\n  # @return [Boolean] true when supervised")
    write_todo('Documentation/UndocumentedBooleanMethods')

    result = run_yard_lint('--check-todo', 'lib')

    assert_equal(1, result[:exit_code], result[:output])
    assert_includes(result[:output], "Documentation/UndocumentedBooleanMethods:\n    - 'lib/q.rb'")
  end

  it 'counts a parent entry that silences a child offense as used' do
    write_todo('Documentation/UndocumentedObjects')

    assert_equal(0, run_yard_lint('lib')[:exit_code])

    result = run_yard_lint('--check-todo', 'lib')

    assert_equal(0, result[:exit_code], result[:output])
    assert_includes(result[:output], 'No unused entries found')
  end
end
