# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'LineLength' do
  attr_reader :test_dir

  before do
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

  def enabled_config(max_length: 120)
    Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/LineLength', 'Enabled', true)
      c.set_validator_config('Documentation/LineLength', 'MaxLength', max_length)
    end
  end

  def line_length_offenses(result)
    result.offenses.select { |o| o[:name].to_s == 'LineLength' }
  end

  it 'disabled by default does not flag long lines' do
    config = Yard::Lint::Config.new

    file = create_test_file('example.rb', <<~RUBY)
      # This is an extremely verbose documentation line that exceeds 120 characters and should only trigger when the validator is enabled.
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config, progress: false)
    assert_empty(line_length_offenses(result), 'Validator should be disabled by default')
  end

  it 'long line detects a docstring line exceeding max length' do
    long_line = '# ' + ('x' * 119)  # 121 chars total
    file = create_test_file('long.rb', <<~RUBY)
      #{long_line}
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = line_length_offenses(result)
    refute_empty(offenses, 'A line exceeding MaxLength should be flagged')
    assert_includes(offenses.first[:message], '121')
    assert_includes(offenses.first[:message], '120')
  end

  it 'short line does not flag a line within max length' do
    file = create_test_file('short.rb', <<~RUBY)
      # Short doc.
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(line_length_offenses(result), 'Lines within MaxLength should not be flagged')
  end

  it 'line exactly at max length is not flagged' do
    line_at_limit = '# ' + ('x' * 118)  # exactly 120 chars
    file = create_test_file('at_limit.rb', <<~RUBY)
      #{line_at_limit}
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(line_length_offenses(result), 'Line exactly at MaxLength should not be flagged')
  end

  it 'custom max length respects a lower MaxLength setting' do
    file = create_test_file('custom.rb', <<~RUBY)
      # This line is 60 characters long, which exceeds 50 chars limit.
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config(max_length: 50), progress: false)
    offenses = line_length_offenses(result)
    refute_empty(offenses, 'Line over custom MaxLength should be flagged')
    assert_includes(offenses.first[:message], '50')
  end

  it 'custom max length does not flag lines within lower MaxLength' do
    file = create_test_file('ok.rb', <<~RUBY)
      # Short doc.
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config(max_length: 50), progress: false)
    assert_empty(line_length_offenses(result))
  end

  it 'multiple long lines in one docstring flags each one' do
    long_line = '# ' + ('y' * 119)  # 121 chars
    file = create_test_file('multi.rb', <<~RUBY)
      #{long_line}
      #{long_line}
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = line_length_offenses(result)
    assert_equal(2, offenses.size, 'Each over-length line should produce a separate offense')
  end

  it 'class documentation flags long lines on a class docstring' do
    long_line = '# ' + ('z' * 119)
    file = create_test_file('cls.rb', <<~RUBY)
      #{long_line}
      class MyClass
        # Normal method doc.
        def go
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = line_length_offenses(result)
    refute_empty(offenses, 'Long line on a class docstring should be flagged')
  end

  it 'mixed methods only flags the offending method docstring' do
    long_line = '# ' + ('a' * 119)
    file = create_test_file('mixed.rb', <<~RUBY)
      # Good class doc.
      class MyClass
        #{long_line}
        def long_doc_method
        end

        # Short doc.
        def short_doc_method
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = line_length_offenses(result)
    assert_equal(1, offenses.size, 'Only the long docstring should produce an offense')
    assert_includes(offenses.first[:message], 'long_doc_method')
  end

  it 'offense message includes line number in file' do
    long_line = '# ' + ('b' * 119)
    file = create_test_file('lineno.rb', <<~RUBY)
      #{long_line}
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = line_length_offenses(result)
    refute_empty(offenses)
    assert_equal(1, offenses.first[:location_line], 'Offense should point to line 1 (the long comment line)')
  end

  it 'offense reports correct file location' do
    long_line = '# ' + ('c' * 119)
    file = create_test_file('location.rb', <<~RUBY)
      #{long_line}
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = line_length_offenses(result)
    refute_empty(offenses)
    assert_equal(file, offenses.first[:location])
  end

  it 'yard tags on long lines also detected when tag line exceeds limit' do
    long_param = '# @param value [String] ' + ('d' * 100)  # > 120
    file = create_test_file('tags.rb', <<~RUBY)
      # Short description.
      #{long_param}
      # @return [String] the value
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = line_length_offenses(result)
    refute_empty(offenses, 'A long @param line should also be flagged')
  end

  it 'methods without docstrings are not flagged' do
    file = create_test_file('no_doc.rb', <<~RUBY)
      class Foo
        def undocumented_method
          :ok
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(line_length_offenses(result), 'Methods without docstrings should not be flagged')
  end

  it 'offense severity is convention by default' do
    long_line = '# ' + ('e' * 119)
    file = create_test_file('severity.rb', <<~RUBY)
      #{long_line}
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = line_length_offenses(result)
    refute_empty(offenses)
    assert_equal('convention', offenses.first[:severity])
  end

  it 'offense validator field identifies the validator' do
    long_line = '# ' + ('f' * 119)
    file = create_test_file('validator_field.rb', <<~RUBY)
      #{long_line}
      def process(value)
        value
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = line_length_offenses(result)
    refute_empty(offenses)
    assert_equal('Documentation/LineLength', offenses.first[:validator])
  end
end
