# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'test_helper'

class DiffModeIntegrationTest < Minitest::Test
  attr_reader :config, :lib_dir, :test_dir

  def setup
    @test_dir = Dir.mktmpdir
    @lib_dir = File.join(test_dir, 'lib')
    @config = Yard::Lint::Config.new
    FileUtils.mkdir_p(lib_dir)
    Dir.chdir(test_dir) do
      # Initialize git repo
      system('git init -q')
      system('git config user.email "test@example.com"')
      system('git config user.name "Test User"')
    end
  end

  def teardown
    FileUtils.rm_rf(test_dir)
  end

  def test_diff_mode_lints_only_changed_files
    # Create initial file and commit
    create_file('lib/old.rb', <<~RUBY)
      # Documented class
      class Old
      end
    RUBY

    git_commit('Initial commit')

    # Create main branch
    Dir.chdir(test_dir) { system('git branch -M main') }

    # Create new file (not committed yet)
    create_file('lib/new.rb', <<~RUBY)
      class New
      end
    RUBY

    git_commit('Add new file')

    # Mock Git.changed_files to return only new.rb
    Yard::Lint::Git.stubs(:changed_files).returns([File.join(lib_dir, 'new.rb')])

    result = Yard::Lint.run(
      path: lib_dir,
      config: config,
      progress: false,
      diff: { mode: :ref, base_ref: 'main~1' }
    )

    # Should only check new.rb (undocumented)
    assert_operator(result.count, :>, 0)
    assert(result.offenses.any? { |o| o[:location].include?('new.rb') })
  end

  def test_diff_mode_auto_detects_main_branch_when_base_ref_is_nil
    create_file('lib/test.rb', 'class Test; end')
    git_commit('Initial commit')

    Dir.chdir(test_dir) { system('git branch -M main') }

    Yard::Lint::Git.stubs(:default_branch).returns('main')
    Yard::Lint::Git.expects(:changed_files).with(nil, lib_dir).returns([])

    Yard::Lint.run(
      path: lib_dir,
      config: config,
      progress: false,
      diff: { mode: :ref, base_ref: nil }
    )
  end

  def test_diff_mode_returns_clean_result_when_no_files_have_changed
    create_file('lib/test.rb', <<~RUBY)
      # Documented class
      class Test
      end
    RUBY

    git_commit('Initial commit')
    Dir.chdir(test_dir) { system('git branch -M main') }

    # Mock empty change set
    Yard::Lint::Git.stubs(:changed_files).returns([])

    result = Yard::Lint.run(
      path: lib_dir,
      config: config,
      progress: false,
      diff: { mode: :ref, base_ref: 'main' }
    )

    assert(result.clean?)
    assert_equal(0, result.count)
  end

  def test_diff_mode_raises_git_error_when_git_command_fails
    Yard::Lint::Git.stubs(:changed_files).raises(Yard::Lint::Git::Error, 'Not a git repository')

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint.run(
        path: lib_dir,
        config: config,
        progress: false,
        diff: { mode: :ref, base_ref: 'main' }
      )
    end
  end

  def test_staged_mode_lints_only_staged_files
    # Create file but don't stage it
    create_file('lib/unstaged.rb', 'class Unstaged; end')

    # Create and stage another file
    create_file('lib/staged.rb', 'class Staged; end')
    Dir.chdir(test_dir) { system('git add lib/staged.rb') }

    # Mock staged_files
    Yard::Lint::Git.stubs(:staged_files).returns([File.join(lib_dir, 'staged.rb')])

    result = Yard::Lint.run(
      path: lib_dir,
      config: config,
      progress: false,
      diff: { mode: :staged }
    )

    # Should only check staged.rb
    assert(result.offenses.any? { |o| o[:location].include?('staged.rb') })
    assert(result.offenses.none? { |o| o[:location].include?('unstaged.rb') })
  end

  def test_staged_mode_returns_clean_result_when_no_files_are_staged
    create_file('lib/test.rb', 'class Test; end')

    # Mock empty staged files
    Yard::Lint::Git.stubs(:staged_files).returns([])

    result = Yard::Lint.run(
      path: lib_dir,
      config: config,
      progress: false,
      diff: { mode: :staged }
    )

    assert(result.clean?)
    assert_equal(0, result.count)
  end

  def test_changed_mode_lints_only_uncommitted_files
    # Create and commit initial file
    create_file('lib/committed.rb', <<~RUBY)
      # Documented class
      class Committed
      end
    RUBY
    git_commit('Initial commit')

    # Modify file but don't commit
    create_file('lib/modified.rb', 'class Modified; end')

    # Mock uncommitted_files
    Yard::Lint::Git.stubs(:uncommitted_files).returns([File.join(lib_dir, 'modified.rb')])

    result = Yard::Lint.run(
      path: lib_dir,
      config: config,
      progress: false,
      diff: { mode: :changed }
    )

    # Should only check modified.rb
    assert(result.offenses.any? { |o| o[:location].include?('modified.rb') })
  end

  def test_exclusion_patterns_with_diff_mode_applies_global_exclusions
    create_file('lib/included.rb', 'class Included; end')
    create_file('spec/excluded.rb', 'class Excluded; end')

    # Configure exclusions
    config_with_exclusions = Yard::Lint::Config.new({
      'AllValidators' => {
        'Exclude' => ['**/spec/**/*']
      }
    })

    # Mock changed files including both
    Yard::Lint::Git.stubs(:changed_files).returns(
      [
        File.join(test_dir, 'lib/included.rb'),
        File.join(test_dir, 'spec/excluded.rb')
      ]
    )

    result = Yard::Lint.run(
      path: test_dir,
      config: config_with_exclusions,
      progress: false,
      diff: { mode: :ref, base_ref: 'main' }
    )

    # Should only check included.rb
    assert(result.offenses.any? { |o| o[:location].include?('included.rb') })
    assert(result.offenses.none? { |o| o[:location].include?('excluded.rb') })
  end

  def test_path_filtering_with_diff_mode_only_lints_files_within_specified_path
    create_file('lib/in_scope.rb', 'class InScope; end')
    create_file('app/out_of_scope.rb', 'class OutOfScope; end')

    # Mock changed files including both
    Yard::Lint::Git.expects(:changed_files).with('main', lib_dir).returns(
      [
        File.join(lib_dir, 'in_scope.rb')
      ]
    )

    Yard::Lint.run(
      path: lib_dir,
      config: config,
      progress: false,
      diff: { mode: :ref, base_ref: 'main' }
    )
  end

  def test_invalid_diff_mode_raises_argumenterror_for_unknown_mode
    assert_raises(ArgumentError) do
      Yard::Lint.run(
        path: lib_dir,
        config: config,
        progress: false,
        diff: { mode: :invalid }
      )
    end
  end

  private

  def create_file(path, content)
    full_path = File.join(test_dir, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  def git_commit(message)
    Dir.chdir(test_dir) do
      system('git add .')
      system("git commit -q -m \"#{message}\"")
    end
  end
end
