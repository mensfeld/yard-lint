# frozen_string_literal: true

require 'English'

# Proves the --explain VALIDATOR flag prints a validator's documentation
# (metadata header, description, configuration snippet, and examples) sourced
# from the validator's own YARD doc block, and reports a clean error for an
# unknown validator name.
describe 'CLI --explain flag' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  def backtrace?(output)
    output.match?(/yard-lint:\d+:in /) || output.include?("\tfrom ")
  end

  it 'explains a validator and exits successfully' do
    output = `#{bin_path} --explain Tags/TypeSyntax 2>&1`

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/^Tags\/TypeSyntax$/, output)
    assert_match(/Enabled by default: true/, output)
    assert_match(/Default severity:\s+warning/, output)
    assert_match(/Configuration keys:.*ValidatedTags/, output)
    assert_match(/Validates YARD type syntax/, output)
    assert_match(/Enabled: false/, output)
    assert_match(/Examples:/, output)
    assert_match(/Bad - /, output)
    assert_match(/Good - /, output)
  end

  it 'explains a validator that has no extra configuration keys' do
    output = `#{bin_path} --explain Warnings/UnknownTag 2>&1`

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_match(/^Warnings\/UnknownTag$/, output)
    assert_match(/Default severity:\s+error/, output)
    refute_match(/Configuration keys:/, output)
    assert_match(/unrecognized YARD tags/i, output)
  end

  it 'reports an unknown validator without a backtrace' do
    output = `#{bin_path} --explain Tags/TypeSyntx 2>&1`

    assert_equal(1, $CHILD_STATUS.exitstatus)
    refute(backtrace?(output), "unknown validator dumped a backtrace:\n#{output}")
    assert_match(/Unknown validator/, output)
    assert_match(/did you mean: Tags\/TypeSyntax/, output)
    assert_match(/Available validators:/, output)
    assert_match(/yard-lint --explain VALIDATOR/, output)
  end
end
