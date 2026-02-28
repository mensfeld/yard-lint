# frozen_string_literal: true

require 'test_helper'

class GlobalExclusionPatternsTest < Minitest::Test
  attr_reader :test_dir, :vendor_dir, :lib_dir, :vendor_file, :lib_file

  def setup
    @test_dir = Dir.mktmpdir('yard-lint-test')
    @vendor_dir = File.join(test_dir, 'vendor', 'bundle')
    @lib_dir = File.join(test_dir, 'lib')
    @vendor_file = File.join(vendor_dir, 'some_gem.rb')
    @lib_file = File.join(lib_dir, 'my_code.rb')
    FileUtils.mkdir_p(vendor_dir)
    FileUtils.mkdir_p(lib_dir)

    # Create files with undocumented methods that will generate offenses
    File.write(vendor_file, <<~RUBY)
      # Vendor gem code
      class VendorGem
        # Method with undocumented params
        def process(arg1, arg2)
          arg1 + arg2
        end
      end
    RUBY

    File.write(lib_file, <<~RUBY)
      # My library code
      class MyCode
        # Method with undocumented params
        def compute(value1, value2)
          value1 * value2
        end
      end
    RUBY
  end

  def teardown
    FileUtils.rm_rf(test_dir)
  end

  def test_excludes_vendor_when_scanning_a_directory_with_absolute_path
    config = Yard::Lint::Config.new do |c|
      c.exclude = ['vendor/**/*']
    end

    result = Yard::Lint.run(path: test_dir, config:)

    file_paths = result.offenses.map { |o| o[:location] }
    refute_includes(file_paths, vendor_file)
    assert_includes(file_paths, lib_file)
  end

  def test_excludes_vendor_when_scanning_with_dot_from_the_target_directory
    config = Yard::Lint::Config.new do |c|
      c.exclude = ['vendor/**/*']
    end

    Dir.chdir(test_dir) do
      result = Yard::Lint.run(path: '.', config:)

      file_paths = result.offenses.map { |o| o[:location] }
      real_vendor_file = File.realpath(vendor_file)
      real_lib_file = File.realpath(lib_file)
      real_file_paths = file_paths.map { |p| File.realpath(p) }

      refute_includes(real_file_paths, real_vendor_file)
      assert_includes(real_file_paths, real_lib_file)
    end
  end

  def test_excludes_deeply_nested_vendor_paths
    deep_vendor_dir = File.join(test_dir, 'vendor', 'bundle', 'ruby', '3.4.0', 'gems', 'ffi')
    FileUtils.mkdir_p(deep_vendor_dir)
    deep_file = File.join(deep_vendor_dir, 'library.rb')

    File.write(deep_file, <<~RUBY)
      # Deep vendor file
      class DeepVendor
        # Method with undocumented params
        def call(input, output)
          input + output
        end
      end
    RUBY

    config = Yard::Lint::Config.new do |c|
      c.exclude = ['vendor/**/*']
    end

    result = Yard::Lint.run(path: test_dir, config:)

    file_paths = result.offenses.map { |o| o[:location] }
    refute_includes(file_paths, deep_file)
  end

  def test_absolute_exclusion_patterns_work
    config = Yard::Lint::Config.new do |c|
      c.exclude = ["#{test_dir}/vendor/**/*"]
    end

    result = Yard::Lint.run(path: test_dir, config:)

    file_paths = result.offenses.map { |o| o[:location] }
    refute_includes(file_paths, vendor_file)
    assert_includes(file_paths, lib_file)
  end

  def test_multiple_exclusion_patterns_excludes_files_matching_any_pattern
    spec_dir = File.join(test_dir, 'spec')
    spec_file = File.join(spec_dir, 'my_spec.rb')
    FileUtils.mkdir_p(spec_dir)
    File.write(spec_file, <<~RUBY)
      # Spec file
      class MySpec
        # Method with undocumented params
        def test_something(expected, actual)
          expected == actual
        end
      end
    RUBY

    config = Yard::Lint::Config.new do |c|
      c.exclude = ['vendor/**/*', 'spec/**/*']
    end

    result = Yard::Lint.run(path: test_dir, config:)

    file_paths = result.offenses.map { |o| o[:location] }
    refute_includes(file_paths, vendor_file)
    refute_includes(file_paths, spec_file)
    assert_includes(file_paths, lib_file)
  end

  def test_handles_patterns_with_curly_braces_extglob
    config = Yard::Lint::Config.new do |c|
      c.exclude = ['{vendor,spec}/**/*']
    end

    result = Yard::Lint.run(path: test_dir, config:)

    file_paths = result.offenses.map { |o| o[:location] }
    refute_includes(file_paths, vendor_file)
    assert_includes(file_paths, lib_file)
  end

  def test_handles_single_file_exclusion_by_relative_path
    config = Yard::Lint::Config.new do |c|
      c.exclude = ['lib/my_code.rb']
    end

    result = Yard::Lint.run(path: test_dir, config:)

    file_paths = result.offenses.map { |o| o[:location] }
    refute_includes(file_paths, lib_file)
  end
end
