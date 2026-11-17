# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

# Proves that text and quickfix output print offense paths relative to the current
# directory when the file is inside it, and absolute when it is outside it.
# Before, both printed the absolute path whatever PATH was given.
describe 'Offense paths in text and quickfix output' do
  attr_reader :project_dir, :outside_dir, :bin_path

  before do
    @project_dir = File.realpath(Dir.mktmpdir('yard-lint-relative-paths-test'))
    @outside_dir = File.realpath(Dir.mktmpdir('yard-lint-relative-paths-outside'))
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)

    source = <<~RUBY
      # Documented module
      module Bad
        # Documented method
        # @return [Object] a
        def self.x(a)
          a
        end
      end
    RUBY

    FileUtils.mkdir_p(File.join(project_dir, 'lib'))
    File.write(File.join(project_dir, 'lib', 'bad.rb'), source)
    File.write(File.join(outside_dir, 'bad.rb'), source)
  end

  after do
    FileUtils.rm_rf(project_dir)
    FileUtils.rm_rf(outside_dir)
  end

  def run_yard_lint(*args)
    stdout, stderr, status = Open3.capture3(bin_path, '--no-progress', *args, chdir: project_dir)
    { output: stdout + stderr, exit_code: status.exitstatus }
  end

  it 'prints a file inside the current directory relative in text output' do
    result = run_yard_lint('lib/')

    assert_equal(1, result[:exit_code], result[:output])
    assert_match(%r{^\[[EWC]\] lib/bad\.rb:5$}, result[:output])
    refute_includes(result[:output], project_dir)
  end

  it 'prints a file inside the current directory relative when PATH is absolute' do
    result = run_yard_lint(File.join(project_dir, 'lib'))

    assert_equal(1, result[:exit_code], result[:output])
    assert_match(%r{^\[[EWC]\] lib/bad\.rb:5$}, result[:output])
  end

  it 'prints a file inside the current directory relative in quickfix output' do
    result = run_yard_lint('--format', 'quickfix', 'lib/')

    assert_equal(1, result[:exit_code], result[:output])
    assert_match(%r{^lib/bad\.rb:5: [EWC]: }, result[:output])
    refute_includes(result[:output], project_dir)
  end

  it 'prints a file outside the current directory absolute in text output' do
    result = run_yard_lint(outside_dir)

    assert_equal(1, result[:exit_code], result[:output])
    assert_match(/^\[[EWC]\] #{Regexp.escape(File.join(outside_dir, 'bad.rb'))}:5$/, result[:output])
  end

  it 'prints a file outside the current directory absolute in quickfix output' do
    result = run_yard_lint('--format', 'quickfix', outside_dir)

    assert_equal(1, result[:exit_code], result[:output])
    assert_match(/^#{Regexp.escape(File.join(outside_dir, 'bad.rb'))}:5: [EWC]: /, result[:output])
  end

  it 'keeps JSON locations absolute' do
    result = run_yard_lint('--format', 'json', 'lib/')

    assert_includes(result[:output], %("location": "#{File.join(project_dir, 'lib', 'bad.rb')}"))
  end
end
