# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# Regression tests for https://github.com/mensfeld/yard-lint/issues/300
#
# Two problems were reported when a blank line separates a non-documentation
# comment from an UNDOCUMENTED definition (typically a block of constants whose
# documentation is intentionally skipped):
#
#   1. A false "Blank line between documentation and definition" offense was
#      raised even though the comment above is not documentation (commented-out
#      code such as `# KEY_F12 = ...`, a `# FIXME` note, a section separator).
#      The validator cannot reliably guess which comments are docs, so a
#      configurable `IgnoredCommentPatterns` option lets the project mark such
#      comments as non-documentation; matching comment lines no longer count as
#      a docstring detached from the definition below them.
#
#   2. The offense carried no validator name (`offense[:validator]` was nil), so
#      it rendered as "    : Blank line ..." in the text output and the user
#      could not tell which validator to disable.
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
  # validator active. Optionally configures IgnoredCommentPatterns.
  def config(ignored_patterns = nil)
    test_config do |c|
      c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', false)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      if ignored_patterns
        c.set_validator_config(
          'Documentation/BlankLineBeforeDefinition', 'IgnoredCommentPatterns', ignored_patterns
        )
      end
    end
  end

  def blank_line_offenses(file, cfg)
    Yard::Lint
      .run(path: file, config: cfg, progress: false)
      .offenses
      .select { |o| o[:name] == 'BlankLineBeforeDefinition' }
  end

  # The exact shape from issue #300: a commented-out constant with a FIXME note,
  # a blank separator line, then more undocumented constants.
  let(:constant_block) do
    create_test_file(<<~RUBY)
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
  end

  it 'flags the constant block by default (no IgnoredCommentPatterns configured)' do
    offenses = blank_line_offenses(constant_block, config)

    # Documents the out-of-the-box behaviour the option exists to tune.
    refute_empty(offenses)
    assert(offenses.any? { |o| o[:message].include?('KEY_C_A') })
  end

  it 'does not flag the constant block when the commented-out line is ignored' do
    # A pattern matching commented-out assignments (a `#` comment whose body is
    # `NAME = ...`) marks that line as non-documentation.
    offenses = blank_line_offenses(constant_block, config(['/\A#\s*\w[\w:]*\s*=/']))

    assert_empty(
      offenses,
      "Expected no blank-line offenses, got: #{offenses.map { |o| o[:message] }.inspect}"
    )
  end

  it 'ignores a comment matched by a plain-substring pattern' do
    # A literal substring (no /.../ delimiters) is matched anywhere in the line.
    offenses = blank_line_offenses(constant_block, config(['FIXME']))

    assert_empty(
      offenses,
      "Expected no blank-line offenses, got: #{offenses.map { |o| o[:message] }.inspect}"
    )
  end

  it 'does not flag an undocumented method preceded by an ignored commented-out definition' do
    file = create_test_file(<<~RUBY)
      # A helper collection
      module Helpers
        def something; end
        # def old_helper; end

        def something_else; end
      end
    RUBY

    offenses = blank_line_offenses(file, config(['/\A#\s*def\s/']))

    assert_empty(
      offenses,
      "Expected no blank-line offenses, got: #{offenses.map { |o| o[:message] }.inspect}"
    )
  end

  it 'still flags a genuine detached docstring even when IgnoredCommentPatterns is set' do
    # A real prose docstring separated from its definition by a blank line must
    # still be reported; an unrelated ignore pattern must not suppress it.
    file = create_test_file(<<~RUBY)
      # A sample module
      module Sample
        # This is documentation for the method.

        def documented_but_detached; end
      end
    RUBY

    offenses = blank_line_offenses(file, config(['FIXME']))

    refute_empty(offenses)
    assert(offenses.any? { |o| o[:message].include?('documented_but_detached') })
  end

  it 'reports the offense with a validator name so it can be disabled' do
    # Issue #300 point 2: the offense must carry its validator name instead of
    # rendering as "    : Blank line ...".
    file = create_test_file(<<~RUBY)
      # A sample module
      module Sample
        # This is documentation for the method.

        def documented_but_detached; end
      end
    RUBY

    offense = blank_line_offenses(file, config).first

    refute_nil(offense, 'Expected a blank-line offense for the detached docstring')
    assert_equal(
      'Documentation/BlankLineBeforeDefinition',
      offense[:validator],
      'Offense must expose its validator name so the text output is not "    : ..."'
    )
  end
end
