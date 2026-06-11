# frozen_string_literal: true

require 'English'
require 'shellwords'

describe 'Quickfix output format' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  it 'outputs one line per offense in file:line: S: Validator: message format' do
    source = "class NoDoc\n  def undoc(arg); arg; end\nend\n"

    Dir.mktmpdir do |dir|
      virtual = File.join(dir, 'sample.rb')
      output = IO.popen(
        "printf '%s' #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
        '--format quickfix --no-progress 2>&1',
        &:read
      )

      refute_equal(0, $CHILD_STATUS.exitstatus)
      lines = output.lines.map(&:chomp).reject(&:empty?)
      refute_empty(lines, 'Expected at least one offense line')

      lines.each do |line|
        assert_match(
          /\A.+:\d+: [EWC?]: .+: .+\z/,
          line,
          "Line does not match quickfix format 'file:line: S: Validator: message': #{line.inspect}"
        )
      end
    end
  end

  it 'includes the file path in each offense line' do
    source = "class NoDoc\n  def undoc(arg); arg; end\nend\n"

    Dir.mktmpdir do |dir|
      virtual = File.join(dir, 'myfile.rb')
      output = IO.popen(
        "printf '%s' #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
        '--format quickfix --no-progress 2>&1',
        &:read
      )

      lines = output.lines.map(&:chomp).reject(&:empty?)
      refute_empty(lines)
      lines.each do |line|
        assert_includes(line, virtual, "Expected file path #{virtual} in line: #{line.inspect}")
      end
    end
  end

  it 'outputs nothing on stdout when there are no offenses' do
    source = <<~RUBY
      # A well-documented class
      class Clean
        # Does something
        # @return [void]
        def go; end
      end
    RUBY

    Dir.mktmpdir do |dir|
      config_file = File.join(dir, '.yard-lint.yml')
      File.write(config_file, <<~YAML)
        AllValidators:
          Exclude: []
        Documentation/UndocumentedObjects:
          Enabled: true
        Documentation/UndocumentedMethodArguments:
          Enabled: false
        Documentation/MissingReturn:
          Enabled: false
        Tags/MissingYield:
          Enabled: false
      YAML

      virtual = File.join(dir, 'clean.rb')
      output = IO.popen(
        "printf '%s' #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
        "--config #{Shellwords.escape(config_file)} --format quickfix --no-progress 2>&1",
        &:read
      )

      assert_equal('', output.strip, "Expected no output for clean source, got: #{output.inspect}")
      assert_equal(0, $CHILD_STATUS.exitstatus)
    end
  end

  it 'exits with non-zero status when offenses are found' do
    source = "class NoDoc\n  def undoc(arg); arg; end\nend\n"

    Dir.mktmpdir do |dir|
      virtual = File.join(dir, 'sample.rb')
      IO.popen(
        "printf '%s' #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
        '--format quickfix --no-progress 2>&1',
        &:read
      )
      refute_equal(0, $CHILD_STATUS.exitstatus)
    end
  end

  it 'uses E for error severity' do
    source = "class NoDoc\n  def undoc(arg); arg; end\nend\n"

    Dir.mktmpdir do |dir|
      config_file = File.join(dir, '.yard-lint.yml')
      File.write(config_file, <<~YAML)
        AllValidators:
          Exclude: []
        Documentation/UndocumentedObjects:
          Enabled: true
          Severity: error
        Documentation/UndocumentedMethodArguments:
          Enabled: false
        Documentation/MissingReturn:
          Enabled: false
        Tags/MissingYield:
          Enabled: false
      YAML

      virtual = File.join(dir, 'sample.rb')
      output = IO.popen(
        "printf '%s' #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
        "--config #{Shellwords.escape(config_file)} --format quickfix --no-progress 2>&1",
        &:read
      )

      assert_match(/: E: /, output, "Expected 'E' severity marker in output: #{output.inspect}")
    end
  end

  it 'uses W for warning severity' do
    source = "class NoDoc\n  def undoc(arg); arg; end\nend\n"

    Dir.mktmpdir do |dir|
      config_file = File.join(dir, '.yard-lint.yml')
      File.write(config_file, <<~YAML)
        AllValidators:
          Exclude: []
        Documentation/UndocumentedObjects:
          Enabled: true
          Severity: warning
        Documentation/UndocumentedMethodArguments:
          Enabled: false
        Documentation/MissingReturn:
          Enabled: false
        Tags/MissingYield:
          Enabled: false
      YAML

      virtual = File.join(dir, 'sample.rb')
      output = IO.popen(
        "printf '%s' #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
        "--config #{Shellwords.escape(config_file)} --format quickfix --no-progress 2>&1",
        &:read
      )

      assert_match(/: W: /, output, "Expected 'W' severity marker in output: #{output.inspect}")
    end
  end

  it 'uses C for convention severity' do
    source = "class NoDoc\n  def undoc(arg); arg; end\nend\n"

    Dir.mktmpdir do |dir|
      config_file = File.join(dir, '.yard-lint.yml')
      File.write(config_file, <<~YAML)
        AllValidators:
          Exclude: []
        Documentation/UndocumentedObjects:
          Enabled: true
          Severity: convention
        Documentation/UndocumentedMethodArguments:
          Enabled: false
        Documentation/MissingReturn:
          Enabled: false
        Tags/MissingYield:
          Enabled: false
      YAML

      virtual = File.join(dir, 'sample.rb')
      output = IO.popen(
        "printf '%s' #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
        "--config #{Shellwords.escape(config_file)} --format quickfix --no-progress 2>&1",
        &:read
      )

      assert_match(/: C: /, output, "Expected 'C' severity marker in output: #{output.inspect}")
    end
  end

  it 'offense messages with embedded newlines are collapsed to a single line' do
    source = "class NoDoc\n  def undoc(arg); arg; end\nend\n"

    Dir.mktmpdir do |dir|
      virtual = File.join(dir, 'sample.rb')
      output = IO.popen(
        "printf '%s' #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
        '--format quickfix --no-progress 2>&1',
        &:read
      )

      output.lines.map(&:chomp).reject(&:empty?).each do |line|
        assert_match(
          /\A.+:\d+: [EWC?]: /,
          line,
          "Line does not start with valid quickfix prefix (possible embedded newline): #{line.inspect}"
        )
      end
    end
  end

  it 'prints coverage failure to stderr and exits non-zero when min_coverage not met' do
    Dir.mktmpdir do |dir|
      # Write an undocumented class to disk so StatsCalculator can count objects
      rb_file = File.join(dir, 'sample.rb')
      File.write(rb_file, "class NoDoc; end\n")

      combined = IO.popen(
        "#{@bin_path} #{Shellwords.escape(rb_file)} --min-coverage 100 --format quickfix --no-progress 2>&1",
        &:read
      )
      stderr_only = IO.popen(
        "#{@bin_path} #{Shellwords.escape(rb_file)} --min-coverage 100 --format quickfix --no-progress 2>&1 >/dev/null",
        &:read
      )

      assert_match(/coverage/i, combined, "Expected coverage message in output: #{combined.inspect}")
      assert_match(/coverage/i, stderr_only, "Expected coverage failure message on stderr: #{stderr_only.inspect}")
      refute_equal(0, $CHILD_STATUS.exitstatus)
    end
  end

  it 'suppresses progress output automatically without --no-progress' do
    source = "class NoDoc\n  def undoc(arg); arg; end\nend\n"

    Dir.mktmpdir do |dir|
      virtual = File.join(dir, 'sample.rb')
      # Without --no-progress and without a TTY, progress should not appear
      output = IO.popen(
        "printf '%s' #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
        '--format quickfix 2>&1',
        &:read
      )

      output.lines.map(&:chomp).reject(&:empty?).each do |line|
        assert_match(
          /\A.+:\d+: [EWC?]: /,
          line,
          "Unexpected non-offense line in quickfix output (progress contamination?): #{line.inspect}"
        )
      end
    end
  end

  it 'unknown format exits with error' do
    Dir.mktmpdir do |dir|
      output = `#{@bin_path} --format bogus #{Shellwords.escape(dir)} --no-progress 2>&1`
      refute_equal(0, $CHILD_STATUS.exitstatus)
      assert_match(/unknown format/i, output)
    end
  end
end
