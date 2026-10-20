# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

# Proves that every Exclude level matches paths relative to the directory of the loaded
# .yard-lint.yml, whatever the PATH argument or the directory yard-lint runs from.
# Before, file selection used the PATH directory and offense filtering used Dir.pwd, so
# `yard-lint lib/` parsed and counted excluded files and `cd lib && yard-lint .` reported them.
describe 'Exclude patterns relative to the config file directory' do
  attr_reader :project_dir, :bin_path

  before do
    @project_dir = Dir.mktmpdir('yard-lint-exclude-base-test')
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)

    FileUtils.mkdir_p(File.join(project_dir, 'lib', 'gen'))
    File.write(File.join(project_dir, 'lib', 'ok.rb'), <<~RUBY)
      # Documented module
      module Ok
        # Documented method
        # @return [Integer] one
        def self.one
          1
        end
      end
    RUBY
    File.write(File.join(project_dir, 'lib', 'gen', 'bad.rb'), <<~RUBY)
      module Gen
        def self.x(a)
          a
        end
      end
    RUBY
  end

  after do
    FileUtils.rm_rf(project_dir)
  end

  def write_config(content)
    File.write(File.join(project_dir, '.yard-lint.yml'), content)
  end

  def run_yard_lint(*args, dir: project_dir)
    stdout, stderr, status = Open3.capture3(bin_path, '--no-progress', *args, chdir: dir)
    { output: stdout + stderr, exit_code: status.exitstatus }
  end

  def lib_dir
    File.join(project_dir, 'lib')
  end

  describe 'with a global Exclude' do
    before do
      write_config("AllValidators:\n  Exclude:\n    - 'lib/gen/**/*'\n")
    end

    it 'does not parse or count an excluded file when PATH is a subdirectory' do
      result = run_yard_lint('lib/', '--stats')

      assert_equal(0, result[:exit_code], result[:output])
      assert_includes(result[:output], 'Total objects:      2')
      assert_includes(result[:output], 'Documentation Coverage: 100.0%')
      refute_includes(result[:output], 'gen/bad.rb')
    end

    it 'ignores an excluded file in --min-coverage when PATH is a subdirectory' do
      result = run_yard_lint('lib/', '--min-coverage', '80')

      assert_equal(0, result[:exit_code], result[:output])
    end

    it 'does not report an excluded file when run from a subdirectory' do
      result = run_yard_lint('.', '--stats', dir: lib_dir)

      assert_equal(0, result[:exit_code], result[:output])
      assert_includes(result[:output], 'Total objects:      2')
      refute_includes(result[:output], 'bad.rb')
    end
  end

  it 'applies a category Exclude when run from a subdirectory' do
    write_config("Documentation:\n  Exclude:\n    - 'lib/gen/**/*'\n")

    result = run_yard_lint('.', dir: lib_dir)

    refute_match(/bad\.rb.*Documentation/, result[:output])
    refute_includes(result[:output], 'UndocumentedObject')
    refute_includes(result[:output], 'UndocumentedMethodArgument')
  end

  it 'applies a per-validator Exclude when run from a subdirectory' do
    write_config(<<~YAML)
      Documentation/UndocumentedObjects:
        Exclude:
          - 'lib/gen/**/*'
      Documentation/UndocumentedMethodArguments:
        Exclude:
          - 'lib/gen/**/*'
    YAML

    result = run_yard_lint('.', dir: lib_dir)

    assert_equal(0, result[:exit_code], result[:output])
    refute_includes(result[:output], 'bad.rb')
  end

  it 'applies the --auto-gen-config baseline when run from a subdirectory' do
    write_config("Tags/Order:\n  Enabled: true\n")
    run_yard_lint('--auto-gen-config', 'lib')

    assert_includes(File.read(File.join(project_dir, '.yard-lint-todo.yml')), "'lib/gen/bad.rb'")

    result = run_yard_lint('.', dir: lib_dir)

    assert_equal(0, result[:exit_code], result[:output])
    refute_includes(result[:output], 'bad.rb')
  end

  describe 'in diff mode' do
    before do
      write_config("AllValidators:\n  Exclude:\n    - 'lib/gen/**/*'\n")
      FileUtils.mv(File.join(lib_dir, 'gen'), File.join(project_dir, 'gen.tmp'))

      git = lambda do |*args|
        _out, err, status = Open3.capture3('git', *args, chdir: project_dir)
        raise "git #{args.join(' ')} failed: #{err}" unless status.success?
      end

      git.call('init', '-q', '-b', 'main')
      git.call('config', 'user.email', 'test@example.com')
      git.call('config', 'user.name', 'Test')
      git.call('add', '.')
      git.call('commit', '-qm', 'init')
      git.call('checkout', '-qb', 'feature')
      FileUtils.mv(File.join(project_dir, 'gen.tmp'), File.join(lib_dir, 'gen'))
      File.write(File.join(lib_dir, 'new.rb'), "# Documented\nmodule New\nend\n")
      git.call('add', '.')
      git.call('commit', '-qm', 'feature')
    end

    it 'does not count an excluded changed file when PATH is a subdirectory' do
      result = run_yard_lint('lib/', '--diff', 'main', '--stats', '--min-coverage', '90')

      assert_equal(0, result[:exit_code], result[:output])
      assert_includes(result[:output], 'Documentation Coverage: 100.0%')
      refute_includes(result[:output], 'bad.rb')
    end

    it 'does not report an excluded changed file when run from a subdirectory' do
      result = run_yard_lint('.', '--diff', 'main', dir: lib_dir)

      assert_equal(0, result[:exit_code], result[:output])
      refute_includes(result[:output], 'bad.rb')
    end
  end
end
