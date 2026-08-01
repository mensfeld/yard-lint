# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# Reproduction / highlight tests for
# https://github.com/mensfeld/yard-lint/issues/300
#
# Two problems are reported when a blank line separates a non-documentation
# comment from an UNDOCUMENTED definition (typically a block of constants whose
# documentation is intentionally skipped):
#
#   1. A false "Blank line between documentation and definition" offense is
#      raised even though the comment above is not documentation for the object
#      (e.g. a commented-out line of code, or a note addressed to maintainers),
#      and the object itself carries no docstring. The blank line is a visual
#      separator, not a detached docstring.
#
#   2. The offense that IS produced carries no validator name (`offense[:validator]`
#      is nil), so it renders as "    : Blank line ..." in the text output and the
#      user cannot tell which validator to disable.
#
# These tests assert the intended behaviour, so they FAIL against the current
# implementation and pin down exactly what a fix must address.
describe 'BlankLineBeforeDefinition issue #300' do
  before do
    @test_dir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_file(content)
    path = File.join(@test_dir, 'input.rb')
    File.write(path, content)
    path
  end

  # UndocumentedObjects disabled (as in the report), only the blank-line
  # validator active.
  def config
    test_config do |c|
      c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', false)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
    end
  end

  def blank_line_offenses(file)
    Yard::Lint
      .run(path: file, config: config, progress: false)
      .offenses
      .select { |o| o[:name] == 'BlankLineBeforeDefinition' }
  end

  it 'does not flag an undocumented constant preceded by a commented-out line and a blank line' do
    # This is the exact shape from issue #300: a commented-out constant with a
    # FIXME note, a blank separator line, then more undocumented constants.
    file = create_test_file(<<~RUBY)
      # Input handling
      module ATui
        # Input keys
        module Input
          KEY_F11 = "\\e[23~"
          # KEY_F12 = "\\e[1~" # FIXME

          KEY_C_A = "\\^A"
          KEY_C_B = "\\^B"
        end
      end
    RUBY

    offenses = blank_line_offenses(file)

    assert_empty(
      offenses,
      "Expected no blank-line offenses, got: #{offenses.map { |o| o[:message] }.inspect}"
    )
  end

  it 'does not flag an undocumented method preceded by a maintainer note across blank lines' do
    # A comment addressed to maintainers (not YARD documentation) sits between
    # two undocumented methods, separated by blank lines on both sides.
    file = create_test_file(<<~RUBY)
      # A helper collection
      module Helpers
        def something; end

        # This note is only here to clarify something for maintainers and is
        # not meant to document the method below.

        def something_else; end
      end
    RUBY

    offenses = blank_line_offenses(file)

    assert_empty(
      offenses,
      "Expected no blank-line offenses, got: #{offenses.map { |o| o[:message] }.inspect}"
    )
  end

  it 'still reports the offense with a validator name so it can be disabled' do
    # Even where an offense is legitimately produced, it must carry its
    # validator name (issue #300 point 2: the message rendered as "    : ...").
    file = create_test_file(<<~RUBY)
      # A documented class whose docstring is detached by a blank line.
      module Sample
        # This is documentation for the method.

        def documented_but_detached; end
      end
    RUBY

    offense = blank_line_offenses(file).first

    refute_nil(offense, 'Expected a blank-line offense for the detached docstring')
    assert_equal(
      'Documentation/BlankLineBeforeDefinition',
      offense[:validator],
      'Offense must expose its validator name so the text output is not "    : ..."'
    )
  end
end
