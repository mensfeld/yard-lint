# frozen_string_literal: true

require 'tmpdir'
require 'open3'
require 'fileutils'

# Proves that Git diff modes find changed files when yard-lint is run from a
# repository subdirectory. `git diff --name-only` reports paths relative to the
# repo root, but the filter expanded them against the current working
# directory - so from a subdirectory every path failed File.exist? and the
# diff modes silently linted nothing.
describe 'Git diff from subdirectory' do
  it 'finds uncommitted changes when run from a repo subdirectory' do
    Dir.mktmpdir do |repo|
      Dir.chdir(repo) do
        system('git', 'init', '--quiet', out: File::NULL, err: File::NULL)
        system('git', 'config', 'user.email', 'test@example.com')
        system('git', 'config', 'user.name', 'Test User')
        FileUtils.mkdir_p('backend/lib')
        File.write('backend/lib/thing.rb', "# A thing.\nclass Thing; end\n")
        system('git', 'add', '.', out: File::NULL, err: File::NULL)
        system('git', 'commit', '--quiet', '-m', 'init', out: File::NULL, err: File::NULL)
        # Uncommitted modification
        File.write('backend/lib/thing.rb', "# A thing.\nclass Thing\n  def call; end\nend\n")
      end

      found = Dir.chdir(File.join(repo, 'backend')) do
        Yard::Lint::Git.uncommitted_files('.')
      end

      assert_equal(1, found.size, 'uncommitted change was not found from a subdirectory')
      assert(found.first.end_with?('backend/lib/thing.rb'), "unexpected path: #{found.first}")
    end
  end
end
