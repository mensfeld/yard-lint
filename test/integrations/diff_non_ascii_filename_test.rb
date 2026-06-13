# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# Proves that diff modes find files whose names contain non-ASCII characters.
# git emits such paths C-quoted (core.quotepath=true), e.g. "caf\303\251.rb",
# so the `.rb` suffix check failed and the file was silently skipped.
describe 'Diff mode with non-ASCII filenames' do
  it 'finds a changed Ruby file with a non-ASCII name' do
    Dir.mktmpdir do |repo|
      Dir.chdir(repo) do
        system('git', 'init', '--quiet', out: File::NULL, err: File::NULL)
        system('git', 'config', 'core.quotepath', 'true')
        system('git', 'config', 'user.email', 'test@example.com')
        system('git', 'config', 'user.name', 'Test User')
        name = 'café.rb'.encode('UTF-8')
        File.write(name, "# A thing.\nclass Thing; end\n")
        system('git', 'add', '.', out: File::NULL, err: File::NULL)
        system('git', 'commit', '--quiet', '-m', 'init', out: File::NULL, err: File::NULL)
        File.write(name, "# A thing.\nclass Thing\n  def x; end\nend\n")

        found = Yard::Lint::Git.uncommitted_files('.')
        assert(found.any? { |f| f.end_with?(name) }, "non-ASCII file not found: #{found.inspect}")
      end
    end
  end
end
