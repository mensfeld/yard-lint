# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint' do
  attr_reader :test_file

  it 'version has a version number' do
    refute_nil(Yard::Lint::VERSION)
    assert_match(/\d+\.\d+\.\d+/, Yard::Lint::VERSION)
  end

  before do
    @test_file = '/tmp/test_lint.rb'
    File.write(test_file, <<~RUBY)
    # A simple test class
    class TestClass
    def method_with_params(arg1, arg2)
    arg1 + arg2
    end
    end
    RUBY
  end

  after do
    FileUtils.rm_f(test_file)
  end

  it 'run returns a result object' do
    result = Yard::Lint.run(path: test_file)

    assert_kind_of(Yard::Lint::Results::Aggregate, result)
  end

  it 'run accepts a config object' do
    config = Yard::Lint::Config.new do |c|
      c.options = ['--private']
      end
    result = Yard::Lint.run(path: test_file, config: config)

    assert_kind_of(Yard::Lint::Results::Aggregate, result)
  end

  it 'run filters excluded files' do
    config = Yard::Lint::Config.new do |c|
      c.exclude = ['/tmp/**/*']
      end
    result = Yard::Lint.run(path: test_file, config: config)

    # Should be clean since file is excluded
    assert_equal(true, result.clean?)
  end
  # Config loading and path expansion are tested through integration tests
  # that call .run() - no need to test private implementation details directly
end

