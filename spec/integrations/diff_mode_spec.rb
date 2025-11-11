# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

RSpec.describe 'Diff Mode Integration', :integration do
  let(:test_dir) { Dir.mktmpdir }
  let(:lib_dir) { File.join(test_dir, 'lib') }
  let(:config) { Yard::Lint::Config.new }

  before do
    FileUtils.mkdir_p(lib_dir)
    Dir.chdir(test_dir) do
      # Initialize git repo
      system('git init -q')
      system('git config user.email "test@example.com"')
      system('git config user.name "Test User"')
    end
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

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

  describe '--diff mode' do
    context 'when files have changed since base ref' do
      it 'lints only changed files' do
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
        allow(Yard::Lint::Git).to receive(:changed_files).and_return([File.join(lib_dir, 'new.rb')])

        result = Yard::Lint.run(
          path: lib_dir,
          config: config,
          progress: false,
          diff: { mode: :ref, base_ref: 'main~1' }
        )

        # Should only check new.rb (undocumented)
        expect(result.count).to be > 0
        expect(result.offenses.any? { |o| o[:location].include?('new.rb') }).to be true
      end

      it 'auto-detects main branch when base_ref is nil' do
        create_file('lib/test.rb', 'class Test; end')
        git_commit('Initial commit')

        Dir.chdir(test_dir) { system('git branch -M main') }

        allow(Yard::Lint::Git).to receive(:default_branch).and_return('main')
        allow(Yard::Lint::Git).to receive(:changed_files).with(nil, lib_dir).and_return([])

        Yard::Lint.run(
          path: lib_dir,
          config: config,
          progress: false,
          diff: { mode: :ref, base_ref: nil }
        )

        expect(Yard::Lint::Git).to have_received(:changed_files).with(nil, lib_dir)
      end
    end

    context 'when no files have changed' do
      it 'returns clean result' do
        create_file('lib/test.rb', <<~RUBY)
          # Documented class
          class Test
          end
        RUBY

        git_commit('Initial commit')
        Dir.chdir(test_dir) { system('git branch -M main') }

        # Mock empty change set
        allow(Yard::Lint::Git).to receive(:changed_files).and_return([])

        result = Yard::Lint.run(
          path: lib_dir,
          config: config,
          progress: false,
          diff: { mode: :ref, base_ref: 'main' }
        )

        expect(result.clean?).to be true
        expect(result.count).to eq(0)
      end
    end

    context 'when git command fails' do
      it 'raises Git::Error' do
        allow(Yard::Lint::Git).to receive(:changed_files)
          .and_raise(Yard::Lint::Git::Error, 'Not a git repository')

        expect do
          Yard::Lint.run(
            path: lib_dir,
            config: config,
            progress: false,
            diff: { mode: :ref, base_ref: 'main' }
          )
        end.to raise_error(Yard::Lint::Git::Error, 'Not a git repository')
      end
    end
  end

  describe '--staged mode' do
    it 'lints only staged files' do
      # Create file but don't stage it
      create_file('lib/unstaged.rb', 'class Unstaged; end')

      # Create and stage another file
      create_file('lib/staged.rb', 'class Staged; end')
      Dir.chdir(test_dir) { system('git add lib/staged.rb') }

      # Mock staged_files
      allow(Yard::Lint::Git).to receive(:staged_files).and_return([File.join(lib_dir, 'staged.rb')])

      result = Yard::Lint.run(
        path: lib_dir,
        config: config,
        progress: false,
        diff: { mode: :staged }
      )

      # Should only check staged.rb
      expect(result.offenses.any? { |o| o[:location].include?('staged.rb') }).to be true
      expect(result.offenses.none? { |o| o[:location].include?('unstaged.rb') }).to be true
    end

    it 'returns clean result when no files are staged' do
      create_file('lib/test.rb', 'class Test; end')

      # Mock empty staged files
      allow(Yard::Lint::Git).to receive(:staged_files).and_return([])

      result = Yard::Lint.run(
        path: lib_dir,
        config: config,
        progress: false,
        diff: { mode: :staged }
      )

      expect(result.clean?).to be true
      expect(result.count).to eq(0)
    end
  end

  describe '--changed mode' do
    it 'lints only uncommitted files' do
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
      allow(Yard::Lint::Git).to receive(:uncommitted_files).and_return([File.join(lib_dir, 'modified.rb')])

      result = Yard::Lint.run(
        path: lib_dir,
        config: config,
        progress: false,
        diff: { mode: :changed }
      )

      # Should only check modified.rb
      expect(result.offenses.any? { |o| o[:location].include?('modified.rb') }).to be true
    end
  end

  describe 'exclusion patterns with diff mode' do
    it 'applies global exclusions to git diff results' do
      create_file('lib/included.rb', 'class Included; end')
      create_file('spec/excluded.rb', 'class Excluded; end')

      # Configure exclusions
      config_with_exclusions = Yard::Lint::Config.new({
        'AllValidators' => {
          'Exclude' => ['**/spec/**/*']
        }
      })

      # Mock changed files including both
      allow(Yard::Lint::Git).to receive(:changed_files).and_return(
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
      expect(result.offenses.any? { |o| o[:location].include?('included.rb') }).to be true
      expect(result.offenses.none? { |o| o[:location].include?('excluded.rb') }).to be true
    end
  end

  describe 'path filtering with diff mode' do
    it 'only lints files within specified path' do
      create_file('lib/in_scope.rb', 'class InScope; end')
      create_file('app/out_of_scope.rb', 'class OutOfScope; end')

      # Mock changed files including both
      allow(Yard::Lint::Git).to receive(:changed_files).with('main', lib_dir).and_return(
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

      # Git module should have been called with lib_dir filter
      expect(Yard::Lint::Git).to have_received(:changed_files).with('main', lib_dir)
    end
  end

  describe 'invalid diff mode' do
    it 'raises ArgumentError for unknown mode' do
      expect do
        Yard::Lint.run(
          path: lib_dir,
          config: config,
          progress: false,
          diff: { mode: :invalid }
        )
      end.to raise_error(ArgumentError, /Unknown diff mode/)
    end
  end
end
