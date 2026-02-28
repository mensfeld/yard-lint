# frozen_string_literal: true

require 'test_helper'

class YardLintGitTest < Minitest::Test
  attr_reader :path

  def setup
    @path = '/home/user/project/lib'
  end

  # .default_branch

  def test_default_branch_when_main_branch_exists_returns_main
    Yard::Lint::Git.stubs(:branch_exists?).with('main').returns(true)

    assert_equal('main', Yard::Lint::Git.default_branch)
  end

  def test_default_branch_when_only_master_branch_exists_returns_master
    Yard::Lint::Git.stubs(:branch_exists?).with('main').returns(false)
    Yard::Lint::Git.stubs(:branch_exists?).with('master').returns(true)

    assert_equal('master', Yard::Lint::Git.default_branch)
  end

  def test_default_branch_when_neither_main_nor_master_exists_returns_nil
    Yard::Lint::Git.stubs(:branch_exists?).with('main').returns(false)
    Yard::Lint::Git.stubs(:branch_exists?).with('master').returns(false)

    assert_nil(Yard::Lint::Git.default_branch)
  end

  # .branch_exists?

  def test_branch_exists_returns_true_when_branch_exists
    Open3.stubs(:capture3)
      .with('git', 'rev-parse', '--verify', '--quiet', 'main')
      .returns(['', '', stub(success?: true)])

    assert_equal(true, Yard::Lint::Git.branch_exists?('main'))
  end

  def test_branch_exists_returns_false_when_branch_does_not_exist
    Open3.stubs(:capture3)
      .with('git', 'rev-parse', '--verify', '--quiet', 'nonexistent')
      .returns(['', '', stub(success?: false)])

    assert_equal(false, Yard::Lint::Git.branch_exists?('nonexistent'))
  end

  # .changed_files

  def test_changed_files_when_base_ref_is_provided_uses_the_provided_base_ref
    Yard::Lint::Git.stubs(:ensure_git_repository!)

    Open3.stubs(:capture3)
      .with('git', 'diff', '--name-only', 'develop...HEAD')
      .returns(["lib/foo.rb\n", '', stub(success?: true)])

    File.stubs(:expand_path).with('/home/user/project/lib').returns('/home/user/project/lib')
    File.stubs(:expand_path).with('lib/foo.rb').returns('/home/user/project/lib/foo.rb')
    File.stubs(:exist?).returns(true)
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.changed_files('develop', path)
    assert_equal(['/home/user/project/lib/foo.rb'], result)
  end

  def test_changed_files_when_base_ref_is_nil_auto_detects_default_branch
    Yard::Lint::Git.stubs(:ensure_git_repository!)
    Yard::Lint::Git.stubs(:default_branch).returns('main')

    Open3.stubs(:capture3)
      .with('git', 'diff', '--name-only', 'main...HEAD')
      .returns(["lib/foo.rb\n", '', stub(success?: true)])

    File.stubs(:expand_path).with('/home/user/project/lib').returns('/home/user/project/lib')
    File.stubs(:expand_path).with('lib/foo.rb').returns('/home/user/project/lib/foo.rb')
    File.stubs(:exist?).returns(true)
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.changed_files(nil, path)
    assert_equal(['/home/user/project/lib/foo.rb'], result)
  end

  def test_changed_files_when_base_ref_is_nil_raises_error_when_default_branch_cannot_be_detected
    Yard::Lint::Git.stubs(:ensure_git_repository!)
    Yard::Lint::Git.stubs(:default_branch).returns(nil)

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint::Git.changed_files(nil, path)
    end
  end

  def test_changed_files_when_git_diff_succeeds_returns_ruby_files_only
    Yard::Lint::Git.stubs(:ensure_git_repository!)
    git_output = "lib/foo.rb\nlib/bar.js\nlib/baz.rb\n"

    Open3.stubs(:capture3)
      .with('git', 'diff', '--name-only', 'main...HEAD')
      .returns([git_output, '', stub(success?: true)])

    File.stubs(:expand_path).with('/home/user/project/lib').returns('/home/user/project/lib')
    File.stubs(:expand_path).with('lib/foo.rb').returns('/home/user/project/lib/foo.rb')
    File.stubs(:expand_path).with('lib/baz.rb').returns('/home/user/project/lib/baz.rb')
    File.stubs(:exist?).returns(true)
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.changed_files('main', path)
    assert_includes(result, '/home/user/project/lib/foo.rb')
    assert_includes(result, '/home/user/project/lib/baz.rb')
    assert_equal(2, result.size)
  end

  def test_changed_files_when_git_diff_succeeds_filters_out_deleted_files
    Yard::Lint::Git.stubs(:ensure_git_repository!)
    git_output = "lib/existing.rb\nlib/deleted.rb\n"

    Open3.stubs(:capture3)
      .with('git', 'diff', '--name-only', 'main...HEAD')
      .returns([git_output, '', stub(success?: true)])

    File.stubs(:expand_path).with('/home/user/project/lib').returns('/home/user/project/lib')
    File.stubs(:expand_path).with('lib/existing.rb').returns('/home/user/project/lib/existing.rb')
    File.stubs(:expand_path).with('lib/deleted.rb').returns('/home/user/project/lib/deleted.rb')
    File.stubs(:exist?).with('/home/user/project/lib/existing.rb').returns(true)
    File.stubs(:exist?).with('/home/user/project/lib/deleted.rb').returns(false)
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.changed_files('main', path)
    assert_equal(['/home/user/project/lib/existing.rb'], result)
  end

  def test_changed_files_when_git_diff_succeeds_filters_files_within_specified_path
    Yard::Lint::Git.stubs(:ensure_git_repository!)
    git_output = "lib/foo.rb\nspec/bar.rb\n"

    Open3.stubs(:capture3)
      .with('git', 'diff', '--name-only', 'main...HEAD')
      .returns([git_output, '', stub(success?: true)])

    File.stubs(:expand_path).with('/home/user/project/lib').returns('/home/user/project/lib')
    File.stubs(:expand_path).with('lib/foo.rb').returns('/home/user/project/lib/foo.rb')
    File.stubs(:expand_path).with('spec/bar.rb').returns('/home/user/project/spec/bar.rb')
    File.stubs(:exist?).returns(true)
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.changed_files('main', '/home/user/project/lib')
    assert_equal(['/home/user/project/lib/foo.rb'], result)
  end

  def test_changed_files_when_git_diff_fails_raises_an_error
    Yard::Lint::Git.stubs(:ensure_git_repository!)

    Open3.stubs(:capture3)
      .with('git', 'diff', '--name-only', 'main...HEAD')
      .returns(['', 'fatal: bad revision', stub(success?: false)])

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint::Git.changed_files('main', path)
    end
  end

  # .staged_files

  def test_staged_files_returns_staged_ruby_files
    Yard::Lint::Git.stubs(:ensure_git_repository!)
    git_output = "lib/staged.rb\nlib/another.rb\n"

    Open3.stubs(:capture3)
      .with('git', 'diff', '--cached', '--name-only', '--diff-filter=ACM')
      .returns([git_output, '', stub(success?: true)])

    File.stubs(:expand_path).with('/home/user/project/lib').returns('/home/user/project/lib')
    File.stubs(:expand_path).with('lib/staged.rb').returns('/home/user/project/lib/staged.rb')
    File.stubs(:expand_path).with('lib/another.rb').returns('/home/user/project/lib/another.rb')
    File.stubs(:exist?).returns(true)
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.staged_files(path)
    assert_includes(result, '/home/user/project/lib/staged.rb')
    assert_includes(result, '/home/user/project/lib/another.rb')
    assert_equal(2, result.size)
  end

  def test_staged_files_excludes_deleted_files_diff_filter_acm
    Yard::Lint::Git.stubs(:ensure_git_repository!)
    git_output = "lib/modified.rb\n"

    Open3.stubs(:capture3)
      .with('git', 'diff', '--cached', '--name-only', '--diff-filter=ACM')
      .returns([git_output, '', stub(success?: true)])

    File.stubs(:expand_path).with('/home/user/project/lib').returns('/home/user/project/lib')
    File.stubs(:expand_path).with('lib/modified.rb').returns('/home/user/project/lib/modified.rb')
    File.stubs(:exist?).returns(true)
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.staged_files(path)
    assert_equal(['/home/user/project/lib/modified.rb'], result)
  end

  def test_staged_files_when_git_diff_fails_raises_an_error
    Yard::Lint::Git.stubs(:ensure_git_repository!)

    Open3.stubs(:capture3)
      .with('git', 'diff', '--cached', '--name-only', '--diff-filter=ACM')
      .returns(['', 'fatal: error', stub(success?: false)])

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint::Git.staged_files(path)
    end
  end

  # .uncommitted_files

  def test_uncommitted_files_returns_uncommitted_ruby_files
    Yard::Lint::Git.stubs(:ensure_git_repository!)
    git_output = "lib/modified.rb\nlib/unstaged.rb\n"

    Open3.stubs(:capture3)
      .with('git', 'diff', '--name-only', 'HEAD')
      .returns([git_output, '', stub(success?: true)])

    File.stubs(:expand_path).with('/home/user/project/lib').returns('/home/user/project/lib')
    File.stubs(:expand_path).with('lib/modified.rb').returns('/home/user/project/lib/modified.rb')
    File.stubs(:expand_path).with('lib/unstaged.rb').returns('/home/user/project/lib/unstaged.rb')
    File.stubs(:exist?).returns(true)
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.uncommitted_files(path)
    assert_includes(result, '/home/user/project/lib/modified.rb')
    assert_includes(result, '/home/user/project/lib/unstaged.rb')
    assert_equal(2, result.size)
  end

  def test_uncommitted_files_when_git_diff_fails_raises_an_error
    Yard::Lint::Git.stubs(:ensure_git_repository!)

    Open3.stubs(:capture3)
      .with('git', 'diff', '--name-only', 'HEAD')
      .returns(['', 'fatal: error', stub(success?: false)])

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint::Git.uncommitted_files(path)
    end
  end

  # .ensure_git_repository!

  def test_ensure_git_repository_does_not_raise_when_in_git_repository
    Open3.stubs(:capture3)
      .with('git', 'rev-parse', '--git-dir')
      .returns(['.git', '', stub(success?: true)])

    Yard::Lint::Git.send(:ensure_git_repository!)
  end

  def test_ensure_git_repository_raises_error_when_not_in_git_repository
    Open3.stubs(:capture3)
      .with('git', 'rev-parse', '--git-dir')
      .returns(['', 'fatal: not a git repository', stub(success?: false)])

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint::Git.send(:ensure_git_repository!)
    end
  end

  # .file_within_path?

  def test_file_within_path_when_base_path_is_a_directory_returns_true_for_files_within_directory
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.send(:file_within_path?, '/home/user/project/lib/foo.rb', '/home/user/project/lib')
    assert_equal(true, result)
  end

  def test_file_within_path_when_base_path_is_a_directory_returns_false_for_files_outside_directory
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.send(:file_within_path?, '/home/user/project/spec/foo.rb', '/home/user/project/lib')
    assert_equal(false, result)
  end

  def test_file_within_path_when_base_path_is_a_file_returns_true_only_for_exact_match
    File.stubs(:directory?).with('/home/user/project/lib/foo.rb').returns(false)

    result = Yard::Lint::Git.send(:file_within_path?, '/home/user/project/lib/foo.rb', '/home/user/project/lib/foo.rb')
    assert_equal(true, result)
  end

  def test_file_within_path_when_base_path_is_a_file_returns_false_for_different_file
    File.stubs(:directory?).with('/home/user/project/lib/foo.rb').returns(false)

    result = Yard::Lint::Git.send(:file_within_path?, '/home/user/project/lib/bar.rb', '/home/user/project/lib/foo.rb')
    assert_equal(false, result)
  end
end
