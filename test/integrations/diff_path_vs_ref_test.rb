# frozen_string_literal: true

require 'English'
require 'shellwords'
require 'tmpdir'
require 'fileutils'

# BUG-022: `--diff [REF]` has an optional argument, so `yard-lint --diff lib/`
# made OptionParser swallow `lib/` as the REF, leaving no PATH - the run then
# tried `git diff lib/...HEAD` and failed with "ambiguous argument". When the
# --diff argument is not a resolvable git ref but is an existing path, it is now
# treated as the PATH (with the base ref auto-detected).
describe 'CLI --diff path vs ref disambiguation' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  # Build a throwaway git repo with a `lib/` subdirectory and a `main` branch.
  def with_repo
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system('git init -q -b main', out: File::NULL, err: File::NULL)
        system('git config user.email t@example.com')
        system('git config user.name test')
        FileUtils.mkdir_p('lib')
        File.write('lib/foo.rb', "# A class.\nclass Foo\n  # Bars.\n  # @return [void]\n  def bar; end\nend\n")
        File.write('.yard-lint.yml', "AllValidators:\n  Exclude: []\n")
        system('git add -A', out: File::NULL, err: File::NULL)
        system('git commit -qm init', out: File::NULL, err: File::NULL)
        yield dir
      end
    end
  end

  def run_cli(args)
    output = `#{bin_path} #{args} --no-progress 2>&1`
    [output, $CHILD_STATUS.exitstatus]
  end

  it 'treats `--diff <existing path>` as the PATH, not a bad git ref' do
    with_repo do
      output, status = run_cli('--diff lib/')
      refute_match(/ambiguous argument/, output, "lib/ should not be used as a git revision: #{output}")
      refute_match(/Git error/, output, "lib/ should not be used as a git revision: #{output}")
      assert_equal(0, status, "expected a clean diff run, got: #{output}")
    end
  end

  it 'still treats `--diff <ref>` as a REF' do
    with_repo do
      # 'main' is a real branch; it must be used as the ref (diff is empty -> clean).
      output, status = run_cli('--diff main')
      refute_match(/ambiguous argument/, output, output)
      assert_equal(0, status, output)
    end
  end

  it 'treats `--diff <ref> <path>` with both arguments correctly' do
    with_repo do
      output, status = run_cli('--diff main lib/')
      refute_match(/ambiguous argument/, output, output)
      assert_equal(0, status, output)
    end
  end

  it 'leaves an unknown ref as a ref (errors), not silently a path' do
    with_repo do
      # A token that is neither a ref nor an existing path stays a ref and errors.
      output, status = run_cli('--diff no_such_ref_or_path')
      refute_equal(0, status, "unknown ref should error: #{output}")
    end
  end
end
