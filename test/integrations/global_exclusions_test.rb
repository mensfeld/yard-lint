# frozen_string_literal: true

require 'test_helper'

describe 'Global Exclusions' do
  attr_reader :test_dir, :vendor_dir, :lib_dir, :vendor_file, :lib_file

  before do
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

  after do
    FileUtils.rm_rf(test_dir)
  end

  it 'excludes vendor when scanning a directory with absolute path' do
    config = Yard::Lint::Config.new do |c|
      c.exclude = ['vendor/**/*']
    end

    result = Yard::Lint.run(path: test_dir, config:)

    file_paths = result.offenses.map { |o| o[:location] }
    refute_includes(file_paths, vendor_file)
    assert_includes(file_paths, lib_file)
  end

  it 'excludes vendor when scanning with dot from the target directory' do
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

  it 'excludes deeply nested vendor paths' do
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

  it 'absolute exclusion patterns work' do
    config = Yard::Lint::Config.new do |c|
      c.exclude = ["#{test_dir}/vendor/**/*"]
    end

    result = Yard::Lint.run(path: test_dir, config:)

    file_paths = result.offenses.map { |o| o[:location] }
    refute_includes(file_paths, vendor_file)
    assert_includes(file_paths, lib_file)
  end

  it 'multiple exclusion patterns excludes files matching any pattern' do
    spec_dir = File.join(test_dir, 'spec')
    spec_file = File.join(spec_dir, 'my_spec.rb')
    FileUtils.mkdir_p(spec_dir)
    File.write(spec_file, <<~RUBY)
      # Spec file
      class MySpec
        # Method with undocumented params
        it 'something' do(expected, actual)
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

  it 'handles patterns with curly braces extglob' do
    config = Yard::Lint::Config.new do |c|
      c.exclude = ['{vendor,spec}/**/*']
    end

    result = Yard::Lint.run(path: test_dir, config:)

    file_paths = result.offenses.map { |o| o[:location] }
    refute_includes(file_paths, vendor_file)
    assert_includes(file_paths, lib_file)
  end

  it 'handles single file exclusion by relative path' do
    config = Yard::Lint::Config.new do |c|
      c.exclude = ['lib/my_code.rb']
    end

    result = Yard::Lint.run(path: test_dir, config:)

    file_paths = result.offenses.map { |o| o[:location] }
    refute_includes(file_paths, lib_file)
  end
end

