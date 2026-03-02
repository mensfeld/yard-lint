# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'Undocumented Options' do
  attr_reader :config

  before do
    @config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedOptions', 'Enabled', true)
    end
    @test_dir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_file(filename, content)
    path = File.join(@test_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  it 'detects options hash parameter without option tags' do
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

  it 'detects opts hash parameter without option tags' do
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

  it 'detects kwargs without option tags' do
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

  it 'does not flag method with option tags' do
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

  it 'does not flag method without options parameter' do
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

