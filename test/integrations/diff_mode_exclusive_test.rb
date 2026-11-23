# frozen_string_literal: true

require 'English'
require 'tmpdir'

# Proves that two diff mode flags together are rejected with a one-line error
# naming both, instead of silently running the last one.
describe 'Diff mode flags are mutually exclusive' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
    @dir = Dir.mktmpdir
    File.write(File.join(@dir, 'foo.rb'), <<~RUBY)
      # frozen_string_literal: true

      # Documented class
      class Foo
      end
    RUBY

    Dir.chdir(@dir) do
      system('git init -q -b master && git add . && ' \
             'git -c user.name=t -c user.email=t@t commit -q -m init', exception: true)
    end
  end

  after do
    FileUtils.rm_rf(@dir)
  end

  [
    [%w[--diff master --staged], '--diff, --staged'],
    [%w[--staged --changed], '--staged, --changed'],
    [%w[--changed --diff], '--changed, --diff']
  ].each do |flags, named|
    it "rejects #{flags.join(' ')}" do
      output = Dir.chdir(@dir) { `#{bin_path} #{flags.join(' ')} . 2>&1` }

      assert_equal(1, $CHILD_STATUS.exitstatus)
      assert_equal(["Error: Diff mode options are mutually exclusive: #{named}"], output.lines.map(&:chomp))
    end
  end

  [%w[--diff master], %w[--staged], %w[--changed], %w[--staged --staged]].each do |flags|
    it "accepts #{flags.join(' ')}" do
      output = Dir.chdir(@dir) { `#{bin_path} #{flags.join(' ')} . 2>&1` }

      assert_equal(0, $CHILD_STATUS.exitstatus, output)
      refute_match(/mutually exclusive/, output)
    end
  end
end
