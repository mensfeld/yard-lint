# frozen_string_literal: true

require 'English'
require 'tmpdir'

# Proves that the CLI reports a clean error (not a raw Ruby backtrace) for an
# unknown command-line flag, for a missing -c config file and for a circular
# inherit_from, in the normal run, --check-todo and --auto-gen-config.
# Previously OptionParser::InvalidOption escaped the unrescued `.parse!`, and
# ConfigFileNotFoundError and CircularDependencyError escaped the config-load
# rescues - all dumping a backtrace.
describe 'CLI error handling' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  def backtrace?(output)
    output.match?(/yard-lint:\d+:in / ) || output.include?("\tfrom ")
  end

  it 'reports an unknown flag without a backtrace' do
    output = `#{bin_path} --definitely-not-a-flag 2>&1`

    assert_equal(1, $CHILD_STATUS.exitstatus)
    refute(backtrace?(output), "unknown flag dumped a backtrace:\n#{output}")
    assert_match(/invalid option|unknown|--definitely-not-a-flag/i, output)
  end

  [[], %w[--check-todo], %w[--auto-gen-config]].each do |flags|
    it "reports a missing -c config file without a backtrace (#{flags.first || 'normal run'})" do
      Dir.mktmpdir do |dir|
        output = `#{bin_path} #{flags.join(' ')} -c #{dir}/missing.yml #{dir} 2>&1`

        assert_equal(1, $CHILD_STATUS.exitstatus)
        refute(backtrace?(output), "missing config dumped a backtrace:\n#{output}")
        assert_match(%r{\AConfiguration Error: Config file not found: #{Regexp.escape(dir)}/missing\.yml\Z}, output)
        refute_path_exists(File.join(dir, '.yard-lint-todo.yml'))
      end
    end

    it "reports a circular inherit_from without a backtrace (#{flags.first || 'normal run'})" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'a.yml'), "inherit_from: b.yml\n")
        File.write(File.join(dir, 'b.yml'), "inherit_from: a.yml\n")

        output = `#{bin_path} #{flags.join(' ')} -c #{dir}/a.yml #{dir} 2>&1`

        assert_equal(1, $CHILD_STATUS.exitstatus)
        refute(backtrace?(output), "circular inherit_from dumped a backtrace:\n#{output}")
        assert_match(%r{\AConfiguration Error: Circular dependency detected: #{Regexp.escape(dir)}/[ab]\.yml\Z}, output)
      end
    end
  end
end
