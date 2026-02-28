# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'test_helper'

class UndocumentedOptionsValidatorTest < Minitest::Test
  attr_reader :config, :test_dir

  def setup
    @config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedOptions', 'Enabled', true)
    end
    @test_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_file(filename, content)
    path = File.join(@test_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def test_detects_options_hash_parameter_without_option_tags
    file = create_test_file('process.rb', <<~RUBY)
      # Process data
      def process(data, options = {})
        # implementation
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    undocumented_options = result.offenses.select { |o| o[:name].to_s == 'UndocumentedOptions' }

    refute_empty(undocumented_options)
    assert_includes(undocumented_options.first[:message], 'process')
    assert_includes(undocumented_options.first[:message], 'options')
  end

  def test_detects_opts_hash_parameter_without_option_tags
    file = create_test_file('execute.rb', <<~RUBY)
      # Execute task
      def execute(data, opts = {})
        # implementation
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    undocumented_options = result.offenses.select { |o| o[:name].to_s == 'UndocumentedOptions' }

    refute_empty(undocumented_options)
    assert_includes(undocumented_options.first[:message], 'opts')
  end

  def test_detects_kwargs_without_option_tags
    file = create_test_file('configure.rb', <<~RUBY)
      # Configure settings
      def configure(**options)
        # implementation
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    undocumented_options = result.offenses.select { |o| o[:name].to_s == 'UndocumentedOptions' }

    refute_empty(undocumented_options)
    assert_includes(undocumented_options.first[:message], '**options')
  end

  def test_does_not_flag_method_with_option_tags
    file = create_test_file('process_with_options.rb', <<~RUBY)
      # Process data
      # @param data [Hash] the data
      # @param options [Hash] processing options
      # @option options [String] :format output format
      def process(data, options = {})
        # implementation
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    undocumented_options = result.offenses.select { |o| o[:name].to_s == 'UndocumentedOptions' }

    assert_empty(undocumented_options)
  end

  def test_does_not_flag_method_without_options_parameter
    file = create_test_file('process_simple.rb', <<~RUBY)
      # Process data
      # @param data [Hash] the data
      def process(data)
        # implementation
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    undocumented_options = result.offenses.select { |o| o[:name].to_s == 'UndocumentedOptions' }

    assert_empty(undocumented_options)
  end
end
