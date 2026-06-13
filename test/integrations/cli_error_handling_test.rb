# frozen_string_literal: true

require 'English'

# Proves that the CLI reports a clean error (not a raw Ruby backtrace) for an
# unknown command-line flag and for a missing -c config file. Previously
# OptionParser::InvalidOption escaped the unrescued `.parse!`, and
# ConfigFileNotFoundError escaped the config-load rescue (which only handled
# InvalidConfigError) - both dumping a backtrace.
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

  it 'reports a missing -c config file without a backtrace' do
    output = `#{bin_path} -c /no/such/yard-lint.yml . 2>&1`

    assert_equal(1, $CHILD_STATUS.exitstatus)
    refute(backtrace?(output), "missing config dumped a backtrace:\n#{output}")
    assert_match(%r{/no/such/yard-lint\.yml}, output)
  end
end
