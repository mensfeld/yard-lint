# frozen_string_literal: true

RSpec.describe Yard::Lint::Git do
  describe '.default_branch' do
    context 'when main branch exists' do
      it 'returns main' do
        allow(described_class).to receive(:branch_exists?).with('main').and_return(true)

        expect(described_class.default_branch).to eq('main')
      end
    end

    context 'when only master branch exists' do
      it 'returns master' do
        allow(described_class).to receive(:branch_exists?).with('main').and_return(false)
        allow(described_class).to receive(:branch_exists?).with('master').and_return(true)

        expect(described_class.default_branch).to eq('master')
      end
    end

    context 'when neither main nor master exists' do
      it 'returns nil' do
        allow(described_class).to receive(:branch_exists?).with('main').and_return(false)
        allow(described_class).to receive(:branch_exists?).with('master').and_return(false)

        expect(described_class.default_branch).to be_nil
      end
    end
  end

  describe '.branch_exists?' do
    it 'returns true when branch exists' do
      allow(Open3).to receive(:capture3)
        .with('git', 'rev-parse', '--verify', '--quiet', 'main')
        .and_return(['', '', instance_double(Process::Status, success?: true)])

      expect(described_class.branch_exists?('main')).to be true
    end

    it 'returns false when branch does not exist' do
      allow(Open3).to receive(:capture3)
        .with('git', 'rev-parse', '--verify', '--quiet', 'nonexistent')
        .and_return(['', '', instance_double(Process::Status, success?: false)])

      expect(described_class.branch_exists?('nonexistent')).to be false
    end
  end

  describe '.changed_files' do
    let(:path) { '/home/user/project/lib' }

    before do
      allow(described_class).to receive(:ensure_git_repository!)
    end

    context 'when base_ref is provided' do
      it 'uses the provided base_ref' do
        allow(Open3).to receive(:capture3)
          .with('git', 'diff', '--name-only', 'develop...HEAD')
          .and_return(["lib/foo.rb\n", '', instance_double(Process::Status, success?: true)])

        allow(File).to receive(:expand_path).with('develop').and_return('develop')
        allow(File).to receive(:expand_path).with('/home/user/project/lib').and_return('/home/user/project/lib')
        allow(File).to receive(:expand_path).with('lib/foo.rb').and_return('/home/user/project/lib/foo.rb')
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:directory?).with('/home/user/project/lib').and_return(true)

        result = described_class.changed_files('develop', path)
        expect(result).to eq(['/home/user/project/lib/foo.rb'])
        expect(Open3).to have_received(:capture3).with('git', 'diff', '--name-only', 'develop...HEAD')
      end
    end

    context 'when base_ref is nil' do
      it 'auto-detects default branch' do
        allow(described_class).to receive(:default_branch).and_return('main')

        allow(Open3).to receive(:capture3)
          .with('git', 'diff', '--name-only', 'main...HEAD')
          .and_return(["lib/foo.rb\n", '', instance_double(Process::Status, success?: true)])

        allow(File).to receive(:expand_path).with('/home/user/project/lib').and_return('/home/user/project/lib')
        allow(File).to receive(:expand_path).with('lib/foo.rb').and_return('/home/user/project/lib/foo.rb')
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:directory?).with('/home/user/project/lib').and_return(true)

        result = described_class.changed_files(nil, path)
        expect(result).to eq(['/home/user/project/lib/foo.rb'])
        expect(Open3).to have_received(:capture3).with('git', 'diff', '--name-only', 'main...HEAD')
      end

      it 'raises error when default branch cannot be detected' do
        allow(described_class).to receive(:default_branch).and_return(nil)

        expect do
          described_class.changed_files(nil, path)
        end.to raise_error(Yard::Lint::Git::Error, 'Could not detect default branch (main/master)')
      end
    end

    context 'when git diff succeeds' do
      it 'returns Ruby files only' do
        git_output = "lib/foo.rb\nlib/bar.js\nlib/baz.rb\n"

        allow(Open3).to receive(:capture3)
          .with('git', 'diff', '--name-only', 'main...HEAD')
          .and_return([git_output, '', instance_double(Process::Status, success?: true)])

        allow(File).to receive(:expand_path).with('/home/user/project/lib').and_return('/home/user/project/lib')
        allow(File).to receive(:expand_path).with('lib/foo.rb').and_return('/home/user/project/lib/foo.rb')
        allow(File).to receive(:expand_path).with('lib/baz.rb').and_return('/home/user/project/lib/baz.rb')
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:directory?).with('/home/user/project/lib').and_return(true)

        result = described_class.changed_files('main', path)
        expect(result).to contain_exactly('/home/user/project/lib/foo.rb', '/home/user/project/lib/baz.rb')
      end

      it 'filters out deleted files' do
        git_output = "lib/existing.rb\nlib/deleted.rb\n"

        allow(Open3).to receive(:capture3)
          .with('git', 'diff', '--name-only', 'main...HEAD')
          .and_return([git_output, '', instance_double(Process::Status, success?: true)])

        allow(File).to receive(:expand_path).with('/home/user/project/lib').and_return('/home/user/project/lib')
        allow(File).to receive(:expand_path).with('lib/existing.rb').and_return('/home/user/project/lib/existing.rb')
        allow(File).to receive(:expand_path).with('lib/deleted.rb').and_return('/home/user/project/lib/deleted.rb')
        allow(File).to receive(:exist?).with('/home/user/project/lib/existing.rb').and_return(true)
        allow(File).to receive(:exist?).with('/home/user/project/lib/deleted.rb').and_return(false)
        allow(File).to receive(:directory?).with('/home/user/project/lib').and_return(true)

        result = described_class.changed_files('main', path)
        expect(result).to eq(['/home/user/project/lib/existing.rb'])
      end

      it 'filters files within specified path' do
        git_output = "lib/foo.rb\nspec/bar.rb\n"

        allow(Open3).to receive(:capture3)
          .with('git', 'diff', '--name-only', 'main...HEAD')
          .and_return([git_output, '', instance_double(Process::Status, success?: true)])

        allow(File).to receive(:expand_path).with('/home/user/project/lib').and_return('/home/user/project/lib')
        allow(File).to receive(:expand_path).with('lib/foo.rb').and_return('/home/user/project/lib/foo.rb')
        allow(File).to receive(:expand_path).with('spec/bar.rb').and_return('/home/user/project/spec/bar.rb')
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:directory?).with('/home/user/project/lib').and_return(true)

        result = described_class.changed_files('main', '/home/user/project/lib')
        expect(result).to eq(['/home/user/project/lib/foo.rb'])
      end
    end

    context 'when git diff fails' do
      it 'raises an error' do
        allow(Open3).to receive(:capture3)
          .with('git', 'diff', '--name-only', 'main...HEAD')
          .and_return(['', 'fatal: bad revision', instance_double(Process::Status, success?: false)])

        expect do
          described_class.changed_files('main', path)
        end.to raise_error(Yard::Lint::Git::Error, /Git diff failed/)
      end
    end
  end

  describe '.staged_files' do
    let(:path) { '/home/user/project/lib' }

    before do
      allow(described_class).to receive(:ensure_git_repository!)
    end

    it 'returns staged Ruby files' do
      git_output = "lib/staged.rb\nlib/another.rb\n"

      allow(Open3).to receive(:capture3)
        .with('git', 'diff', '--cached', '--name-only', '--diff-filter=ACM')
        .and_return([git_output, '', instance_double(Process::Status, success?: true)])

      allow(File).to receive(:expand_path).with('/home/user/project/lib').and_return('/home/user/project/lib')
      allow(File).to receive(:expand_path).with('lib/staged.rb').and_return('/home/user/project/lib/staged.rb')
      allow(File).to receive(:expand_path).with('lib/another.rb').and_return('/home/user/project/lib/another.rb')
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:directory?).with('/home/user/project/lib').and_return(true)

      result = described_class.staged_files(path)
      expect(result).to contain_exactly('/home/user/project/lib/staged.rb', '/home/user/project/lib/another.rb')
    end

    it 'excludes deleted files (diff-filter=ACM)' do
      git_output = "lib/modified.rb\n"

      allow(Open3).to receive(:capture3)
        .with('git', 'diff', '--cached', '--name-only', '--diff-filter=ACM')
        .and_return([git_output, '', instance_double(Process::Status, success?: true)])

      allow(File).to receive(:expand_path).with('/home/user/project/lib').and_return('/home/user/project/lib')
      allow(File).to receive(:expand_path).with('lib/modified.rb').and_return('/home/user/project/lib/modified.rb')
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:directory?).with('/home/user/project/lib').and_return(true)

      result = described_class.staged_files(path)
      expect(result).to eq(['/home/user/project/lib/modified.rb'])
    end

    context 'when git diff fails' do
      it 'raises an error' do
        allow(Open3).to receive(:capture3)
          .with('git', 'diff', '--cached', '--name-only', '--diff-filter=ACM')
          .and_return(['', 'fatal: error', instance_double(Process::Status, success?: false)])

        expect do
          described_class.staged_files(path)
        end.to raise_error(Yard::Lint::Git::Error, /Git diff failed/)
      end
    end
  end

  describe '.uncommitted_files' do
    let(:path) { '/home/user/project/lib' }

    before do
      allow(described_class).to receive(:ensure_git_repository!)
    end

    it 'returns uncommitted Ruby files' do
      git_output = "lib/modified.rb\nlib/unstaged.rb\n"

      allow(Open3).to receive(:capture3)
        .with('git', 'diff', '--name-only', 'HEAD')
        .and_return([git_output, '', instance_double(Process::Status, success?: true)])

      allow(File).to receive(:expand_path).with('/home/user/project/lib').and_return('/home/user/project/lib')
      allow(File).to receive(:expand_path).with('lib/modified.rb').and_return('/home/user/project/lib/modified.rb')
      allow(File).to receive(:expand_path).with('lib/unstaged.rb').and_return('/home/user/project/lib/unstaged.rb')
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:directory?).with('/home/user/project/lib').and_return(true)

      result = described_class.uncommitted_files(path)
      expect(result).to contain_exactly('/home/user/project/lib/modified.rb', '/home/user/project/lib/unstaged.rb')
    end

    context 'when git diff fails' do
      it 'raises an error' do
        allow(Open3).to receive(:capture3)
          .with('git', 'diff', '--name-only', 'HEAD')
          .and_return(['', 'fatal: error', instance_double(Process::Status, success?: false)])

        expect do
          described_class.uncommitted_files(path)
        end.to raise_error(Yard::Lint::Git::Error, /Git diff failed/)
      end
    end
  end

  describe '.ensure_git_repository!' do
    it 'does not raise when in git repository' do
      allow(Open3).to receive(:capture3)
        .with('git', 'rev-parse', '--git-dir')
        .and_return(['.git', '', instance_double(Process::Status, success?: true)])

      expect { described_class.send(:ensure_git_repository!) }.not_to raise_error
    end

    it 'raises error when not in git repository' do
      allow(Open3).to receive(:capture3)
        .with('git', 'rev-parse', '--git-dir')
        .and_return(['', 'fatal: not a git repository', instance_double(Process::Status, success?: false)])

      expect do
        described_class.send(:ensure_git_repository!)
      end.to raise_error(Yard::Lint::Git::Error, 'Not a git repository')
    end
  end

  describe '.file_within_path?' do
    context 'when base_path is a directory' do
      it 'returns true for files within directory' do
        allow(File).to receive(:directory?).with('/home/user/project/lib').and_return(true)

        result = described_class.send(:file_within_path?, '/home/user/project/lib/foo.rb', '/home/user/project/lib')
        expect(result).to be true
      end

      it 'returns false for files outside directory' do
        allow(File).to receive(:directory?).with('/home/user/project/lib').and_return(true)

        result = described_class.send(:file_within_path?, '/home/user/project/spec/foo.rb', '/home/user/project/lib')
        expect(result).to be false
      end
    end

    context 'when base_path is a file' do
      it 'returns true only for exact match' do
        allow(File).to receive(:directory?).with('/home/user/project/lib/foo.rb').and_return(false)

        result = described_class.send(:file_within_path?, '/home/user/project/lib/foo.rb', '/home/user/project/lib/foo.rb')
        expect(result).to be true
      end

      it 'returns false for different file' do
        allow(File).to receive(:directory?).with('/home/user/project/lib/foo.rb').and_return(false)

        result = described_class.send(:file_within_path?, '/home/user/project/lib/bar.rb', '/home/user/project/lib/foo.rb')
        expect(result).to be false
      end
    end
  end
end
