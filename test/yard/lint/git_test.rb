# frozen_string_literal: true

describe 'Yard::Lint::Git' do
  attr_reader :path

  before do
    @path = '/home/user/project/lib'
  end

  # .default_branch

  it 'default branch when main branch exists returns main' do
    Yard::Lint::Git.stubs(:branch_exists?).with('main').returns(true)

    assert_equal('main', Yard::Lint::Git.default_branch)
  end

  it 'default branch when only master branch exists returns master' do
    Yard::Lint::Git.stubs(:branch_exists?).with('main').returns(false)
    Yard::Lint::Git.stubs(:branch_exists?).with('master').returns(true)

    assert_equal('master', Yard::Lint::Git.default_branch)
  end

  it 'default branch when neither main nor master exists returns nil' do
    Yard::Lint::Git.stubs(:branch_exists?).with('main').returns(false)
    Yard::Lint::Git.stubs(:branch_exists?).with('master').returns(false)

    assert_nil(Yard::Lint::Git.default_branch)
  end

  # .branch_exists?

  it 'branch exists returns true when branch exists' do
    Open3.stubs(:capture3)
      .with('git', 'rev-parse', '--verify', '--quiet', 'main')
      .returns(['', '', stub(success?: true)])

    assert_equal(true, Yard::Lint::Git.branch_exists?('main'))
  end

  it 'branch exists returns false when branch does not exist' do
    Open3.stubs(:capture3)
      .with('git', 'rev-parse', '--verify', '--quiet', 'nonexistent')
      .returns(['', '', stub(success?: false)])

    assert_equal(false, Yard::Lint::Git.branch_exists?('nonexistent'))
  end

  # .changed_files

  it 'changed files when base ref is provided uses the provided base ref' do
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

  it 'changed files when base ref is nil auto detects default branch' do
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

  it 'changed files when base ref is nil raises error when default branch cannot be detected' do
    Yard::Lint::Git.stubs(:ensure_git_repository!)
    Yard::Lint::Git.stubs(:default_branch).returns(nil)

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint::Git.changed_files(nil, path)
    end
  end

  it 'changed files when git diff succeeds returns ruby files only' do
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

  it 'changed files when git diff succeeds filters out deleted files' do
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

  it 'changed files when git diff succeeds filters files within specified path' do
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

  it 'changed files when git diff fails raises an error' do
    Yard::Lint::Git.stubs(:ensure_git_repository!)

    Open3.stubs(:capture3)
      .with('git', 'diff', '--name-only', 'main...HEAD')
      .returns(['', 'fatal: bad revision', stub(success?: false)])

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint::Git.changed_files('main', path)
    end
  end

  # .staged_files

  it 'staged files returns staged ruby files' do
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

  it 'staged files excludes deleted files diff filter acm' do
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

  it 'staged files when git diff fails raises an error' do
    Yard::Lint::Git.stubs(:ensure_git_repository!)

    Open3.stubs(:capture3)
      .with('git', 'diff', '--cached', '--name-only', '--diff-filter=ACM')
      .returns(['', 'fatal: error', stub(success?: false)])

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint::Git.staged_files(path)
    end
  end

  # .uncommitted_files

  it 'uncommitted files returns uncommitted ruby files' do
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

  it 'uncommitted files when git diff fails raises an error' do
    Yard::Lint::Git.stubs(:ensure_git_repository!)

    Open3.stubs(:capture3)
      .with('git', 'diff', '--name-only', 'HEAD')
      .returns(['', 'fatal: error', stub(success?: false)])

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint::Git.uncommitted_files(path)
    end
  end

  # .ensure_git_repository!

  it 'ensure git repository does not raise when in git repository' do
    Open3.stubs(:capture3)
      .with('git', 'rev-parse', '--git-dir')
      .returns(['.git', '', stub(success?: true)])

    Yard::Lint::Git.send(:ensure_git_repository!)
  end

  it 'ensure git repository raises error when not in git repository' do
    Open3.stubs(:capture3)
      .with('git', 'rev-parse', '--git-dir')
      .returns(['', 'fatal: not a git repository', stub(success?: false)])

    assert_raises(Yard::Lint::Git::Error) do
      Yard::Lint::Git.send(:ensure_git_repository!)
    end
  end

  # .file_within_path?

  it 'file within path when base path is a directory returns true for files within directory' do
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.send(:file_within_path?, '/home/user/project/lib/foo.rb', '/home/user/project/lib')
    assert_equal(true, result)
  end

  it 'file within path when base path is a directory returns false for files outside directory' do
    File.stubs(:directory?).with('/home/user/project/lib').returns(true)

    result = Yard::Lint::Git.send(:file_within_path?, '/home/user/project/spec/foo.rb', '/home/user/project/lib')
    assert_equal(false, result)
  end

  it 'file within path when base path is a file returns true only for exact match' do
    File.stubs(:directory?).with('/home/user/project/lib/foo.rb').returns(false)

    result = Yard::Lint::Git.send(:file_within_path?, '/home/user/project/lib/foo.rb', '/home/user/project/lib/foo.rb')
    assert_equal(true, result)
  end

  it 'file within path when base path is a file returns false for different file' do
    File.stubs(:directory?).with('/home/user/project/lib/foo.rb').returns(false)

    result = Yard::Lint::Git.send(:file_within_path?, '/home/user/project/lib/bar.rb', '/home/user/project/lib/foo.rb')
    assert_equal(false, result)
  end
end

