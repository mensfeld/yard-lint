# frozen_string_literal: true

require 'English'
require 'json'
require 'shellwords'
require 'tmpdir'

# Proves that a category-level Severity (e.g. `Documentation: { Severity: ... }`)
# is honored end-to-end: it sets the reported severity of every validator in
# that category, is overridden by a per-validator Severity, feeds the
# FailOnSeverity exit-code decision, never changes the reported offense count,
# and is rejected when given an invalid value. An explicit `-c` config keeps the
# run from picking up the repository's own .yard-lint.yml.
describe 'CLI category-level severity' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  def backtrace?(output)
    output.match?(/yard-lint:\d+:in /) || output.include?("\tfrom ")
  end

  # Lints an undocumented file (which trips Documentation/UndocumentedObjects)
  # with the given .yard-lint.yml body, returning [parsed_json, exit_status].
  def lint_with_config(config_body)
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'foo.rb'), "class Foo\n  def bar\n  end\nend\n")
      config = File.join(dir, '.yard-lint.yml')
      File.write(config, config_body)

      output = IO.popen(
        "#{bin_path} -c #{Shellwords.escape(config)} " \
        '--only Documentation/UndocumentedObjects --format json --no-progress ' \
        "#{Shellwords.escape(File.join(dir, 'foo.rb'))} 2>&1",
        &:read
      )
      [output, $CHILD_STATUS.exitstatus]
    end
  end

  it 'uses the validator built-in default when no severity is configured' do
    output, = lint_with_config('')
    offenses = JSON.parse(output)['offenses']

    refute_empty(offenses)
    assert(offenses.all? { |o| o['severity'] == 'warning' }, "expected all warning, got #{output}")
  end

  it 'applies a category-level Severity to every validator in that category' do
    output, = lint_with_config("Documentation:\n  Severity: error\n")
    offenses = JSON.parse(output)['offenses']

    refute_empty(offenses)
    assert(offenses.all? { |o| o['severity'] == 'error' }, "expected all error, got #{output}")
  end

  it 'lets a per-validator Severity override the category-level Severity' do
    output, = lint_with_config(<<~YAML)
      Documentation:
        Severity: error
      Documentation/UndocumentedObjects:
        Severity: convention
    YAML
    offenses = JSON.parse(output)['offenses']

    refute_empty(offenses)
    assert(offenses.all? { |o| o['severity'] == 'convention' }, "expected all convention, got #{output}")
  end

  it 'feeds the FailOnSeverity exit code while keeping the offense count truthful' do
    # Default FailOnSeverity is warning. Built-in default severity is warning, so
    # the run fails; lowering the category to convention drops it below the
    # threshold and the run passes - but the offenses are still reported.
    default_output, default_status = lint_with_config('')
    lowered_output, lowered_status = lint_with_config("Documentation:\n  Severity: convention\n")

    assert_equal(1, default_status)
    assert_equal(0, lowered_status)
    assert_equal(
      JSON.parse(default_output)['offense_count'],
      JSON.parse(lowered_output)['offense_count'],
      'lowering severity must not change the reported offense count'
    )
    assert(JSON.parse(lowered_output)['offense_count'].positive?)
  end

  it 'rejects an invalid category-level Severity without a backtrace' do
    output, status = lint_with_config("Documentation:\n  Severity: bogus\n")

    assert_equal(1, status)
    refute(backtrace?(output), "invalid category severity dumped a backtrace:\n#{output}")
    assert_match(/Invalid Severity for category Documentation/, output)
  end
end
