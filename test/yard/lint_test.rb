# frozen_string_literal: true

require 'test_helper'

class YardLintTest < Minitest::Test
  attr_reader :test_file

  def test_version_has_a_version_number
    refute_nil(Yard::Lint::VERSION)
    assert_match(/\d+\.\d+\.\d+/, Yard::Lint::VERSION)
  end

  def setup
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

  def teardown
    FileUtils.rm_f(test_file)
  end

  def test_run_returns_a_result_object
    result = Yard::Lint.run(path: test_file)

    assert_kind_of(Yard::Lint::Results::Aggregate, result)
  end

  def test_run_accepts_a_config_object
    config = Yard::Lint::Config.new do |c|
      c.options = ['--private']
      end
    result = Yard::Lint.run(path: test_file, config: config)

    assert_kind_of(Yard::Lint::Results::Aggregate, result)
  end

  def test_run_filters_excluded_files
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

