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
#      raised even though the comment above is commented-out code (e.g.
#      `# KEY_F12 = ...`), not documentation, and the object itself carries no
#      docstring. The blank line is a visual separator, not a detached docstring.
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

  it 'does not flag an undocumented method preceded by a commented-out definition' do
    # A commented-out method sits directly below a real one (a common way to
    # park dead code), then a blank line, then the next undocumented method.
    # The commented-out line is code, not documentation for something_else.
    file = create_test_file(<<~RUBY)
      # A helper collection
      module Helpers
        def something; end
        # def old_helper; end

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
