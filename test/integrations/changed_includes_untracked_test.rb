# frozen_string_literal: true

require 'tmpdir'
require 'open3'
require 'fileutils'

# Proves that --changed (uncommitted_files) includes untracked files. It used
# `git diff --name-only HEAD`, which lists only tracked changes, so a brand-new
# not-yet-staged .rb file was never linted despite being a working-dir change.
describe 'changed mode includes untracked files' do
  it 'finds a new untracked Ruby file' do
    Dir.mktmpdir do |repo|
      Dir.chdir(repo) do
        system('git', 'init', '--quiet', out: File::NULL, err: File::NULL)
        system('git', 'config', 'user.email', 'test@example.com')
        system('git', 'config', 'user.name', 'Test User')
        File.write('committed.rb', "# A thing.\nclass Thing; end\n")
        system('git', 'add', '.', out: File::NULL, err: File::NULL)
        system('git', 'commit', '--quiet', '-m', 'init', out: File::NULL, err: File::NULL)
        # Brand-new untracked file
        File.write('fresh.rb', "class Fresh; end\n")

        found = Yard::Lint::Git.uncommitted_files('.')
        assert(found.any? { |f| f.end_with?('fresh.rb') }, "untracked file not found: #{found.inspect}")
      end
    end
  end
end
