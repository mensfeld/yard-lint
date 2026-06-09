# frozen_string_literal: true

require 'English'
require 'json'
require 'shellwords'

describe 'Cli' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  it 'version flag displays the version number' do
    output = `#{@bin_path} --version 2>&1`
    assert_equal(true, $CHILD_STATUS.success?)
    assert_match(/yard-lint \d+\.\d+\.\d+/, output)
    assert_equal("yard-lint #{Yard::Lint::VERSION}", output.strip)
  end

  it 'version flag exits successfully' do
    `#{@bin_path} --version 2>&1`
    assert_equal(0, $CHILD_STATUS.exitstatus)
  end

  it 'version flag v flag displays the version number' do
    output = `#{@bin_path} -v 2>&1`
    assert_equal(true, $CHILD_STATUS.success?)
    assert_match(/yard-lint \d+\.\d+\.\d+/, output)
    assert_equal("yard-lint #{Yard::Lint::VERSION}", output.strip)
  end

  it 'v flag exits successfully' do
    `#{@bin_path} -v 2>&1`
    assert_equal(0, $CHILD_STATUS.exitstatus)
  end

  describe '--stdin flag' do
    it 'lints source from stdin and exits with offense exit code' do
      source = <<~RUBY
        class StdinUndocumented
          def undoc(arg); arg; end
        end
      RUBY

      Dir.mktmpdir do |dir|
        virtual = File.join(dir, 'stdin_test.rb')
        output = IO.popen(
          "echo #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} --no-progress 2>&1",
          &:read
        )
        # Should find offenses (undocumented class/method)
        refute_equal(0, $CHILD_STATUS.exitstatus, "Expected non-zero exit for offenses, output: #{output}")
      end
    end

    it 'lints clean source from stdin and exits 0' do
      source = <<~RUBY
        # A well-documented class
        class StdinClean
          # Does something
          # @return [void]
          def go
          end
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

        virtual = File.join(dir, 'stdin_clean.rb')
        output = IO.popen(
          "echo #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
          "--config #{Shellwords.escape(config_file)} --no-progress 2>&1",
          &:read
        )
        assert_equal(0, $CHILD_STATUS.exitstatus,
                     "Expected clean exit for well-documented source, output: #{output}")
      end
    end

    it 'reports error when --stdin is used without an explicit file path' do
      output = `echo 'class Foo; end' | #{@bin_path} --stdin --no-progress 2>&1`
      refute_equal(0, $CHILD_STATUS.exitstatus)
      assert_match(/explicit file path/i, output)
    end

    it 'reports offense location as the provided path' do
      source = "class NoDoc\n  def undoc(arg); arg; end\nend\n"

      Dir.mktmpdir do |dir|
        virtual = File.join(dir, 'virtual_location.rb')
        output = IO.popen(
          "printf #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} --no-progress 2>&1",
          &:read
        )
        assert_includes(output, virtual,
                        "Expected virtual path in offense output, got:\n#{output}")
      end
    end

    it 'supports --format json with --stdin' do
      source = "class JsonStdin\n  def undoc(arg); arg; end\nend\n"

      Dir.mktmpdir do |dir|
        virtual = File.join(dir, 'json_stdin.rb')
        output = IO.popen(
          "printf #{Shellwords.escape(source)} | #{@bin_path} --stdin #{Shellwords.escape(virtual)} " \
          '--format json --no-progress 2>&1',
          &:read
        )
        parsed = JSON.parse(output)
        assert(parsed.key?('offense_count'))
        assert(parsed.key?('offenses'))
      end
    end
  end
end

