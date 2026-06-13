# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# BUG-082: a Ruby file YARD cannot parse used to be silently skipped - it
# registered no objects, produced no offense, and the run could exit 0 over code
# that does not even parse. Warnings/SyntaxError surfaces the parser error as an
# offense (severity error by default) so the run exits non-zero.
describe 'Warnings/SyntaxError' do
  attr_reader :test_dir

  before do
    @test_dir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def write_file(name, content)
    path = File.join(@test_dir, name)
    File.write(path, content)
    path
  end

  def syntax_offenses(result)
    result.offenses.select { |o| o[:name].to_s == 'SyntaxError' }
  end

  it 'is enabled by default' do
    file = write_file('broken.rb', "# @param x [Integer] v\ndef foo(x\n  x + 1\nend\n")
    result = Yard::Lint.run(path: file, config: test_config, progress: false)
    refute_empty(syntax_offenses(result), 'a syntax error should be flagged with the default config')
  end

  it 'flags a file with a syntax error and reports its location' do
    file = write_file('broken.rb', "# @param x [Integer] v\ndef foo(x\n  x + 1\nend\n")
    config = test_config { |c| c.set_validator_config('Warnings/SyntaxError', 'Enabled', true) }
    result = Yard::Lint.run(path: file, config: config, progress: false)

    offenses = syntax_offenses(result)
    assert_equal(1, offenses.count)
    assert_equal('error', offenses.first[:severity])
    assert_equal(file, offenses.first[:location])
    assert_includes(offenses.first[:message], 'could not be parsed')
  end

  it 'produces an error-severity offense (non-zero exit under default FailOnSeverity)' do
    file = write_file('broken.rb', "def foo(x\nend\n")
    config = test_config { |c| c.set_validator_config('Warnings/SyntaxError', 'Enabled', true) }
    result = Yard::Lint.run(path: file, config: config, progress: false)

    assert(result.statistics[:error] >= 1, 'syntax error should count as an error-severity offense')
    refute_equal(0, result.exit_code, 'run must not exit 0 when a file has a syntax error')
  end

  it 'does not flag a file that parses cleanly' do
    file = write_file('ok.rb', "# A method.\n# @param x [Integer] v\n# @return [Integer] doubled\ndef foo(x)\n  x * 2\nend\n")
    config = test_config { |c| c.set_validator_config('Warnings/SyntaxError', 'Enabled', true) }
    result = Yard::Lint.run(path: file, config: config, progress: false)

    assert_empty(syntax_offenses(result))
  end

  it 'reports exactly one offense per broken file (not the sibling error/stack-trace lines)' do
    file = write_file('broken.rb', "def foo(x\n  x + 1\nend\n")
    config = test_config { |c| c.set_validator_config('Warnings/SyntaxError', 'Enabled', true) }
    result = Yard::Lint.run(path: file, config: config, progress: false)

    assert_equal(1, syntax_offenses(result).count)
  end

  it 'can be disabled' do
    file = write_file('broken.rb', "def foo(x\nend\n")
    config = test_config { |c| c.set_validator_config('Warnings/SyntaxError', 'Enabled', false) }
    result = Yard::Lint.run(path: file, config: config, progress: false)

    assert_empty(syntax_offenses(result))
  end
end
