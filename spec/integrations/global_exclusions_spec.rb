# frozen_string_literal: true

RSpec.describe 'Global exclusion patterns', :integration, type: :feature do
  let(:test_dir) { Dir.mktmpdir('yard-lint-test') }
  let(:vendor_dir) { File.join(test_dir, 'vendor', 'bundle') }
  let(:lib_dir) { File.join(test_dir, 'lib') }
  let(:vendor_file) { File.join(vendor_dir, 'some_gem.rb') }
  let(:lib_file) { File.join(lib_dir, 'my_code.rb') }

  before do
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

  after { FileUtils.rm_rf(test_dir) }

  describe 'relative exclusion patterns with absolute directory paths' do
    it 'excludes vendor/**/* when scanning a directory with absolute path' do
      config = Yard::Lint::Config.new do |c|
        c.exclude = ['vendor/**/*']
      end

      result = Yard::Lint.run(path: test_dir, config:)

      # Should only find offenses in lib_file, not in vendor_file
      file_paths = result.offenses.map { |o| o[:location] }
      expect(file_paths).not_to include(vendor_file)
      expect(file_paths).to include(lib_file)
    end

    it 'excludes vendor/**/* when scanning with "." from the target directory' do
      config = Yard::Lint::Config.new do |c|
        c.exclude = ['vendor/**/*']
      end

      # Simulate running from within the test directory
      Dir.chdir(test_dir) do
        result = Yard::Lint.run(path: '.', config:)

        file_paths = result.offenses.map { |o| o[:location] }
        # Use File.realpath to handle macOS /var -> /private/var symlink
        real_vendor_file = File.realpath(vendor_file)
        real_lib_file = File.realpath(lib_file)
        real_file_paths = file_paths.map { |p| File.realpath(p) }

        expect(real_file_paths).not_to include(real_vendor_file)
        expect(real_file_paths).to include(real_lib_file)
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
      expect(file_paths).not_to include(deep_file)
    end
  end

  describe 'absolute exclusion patterns' do
    it 'works with absolute patterns' do
      config = Yard::Lint::Config.new do |c|
        c.exclude = ["#{test_dir}/vendor/**/*"]
      end

      result = Yard::Lint.run(path: test_dir, config:)

      file_paths = result.offenses.map { |o| o[:location] }
      expect(file_paths).not_to include(vendor_file)
      expect(file_paths).to include(lib_file)
    end
  end

  describe 'multiple exclusion patterns' do
    let(:spec_dir) { File.join(test_dir, 'spec') }
    let(:spec_file) { File.join(spec_dir, 'my_spec.rb') }

    before do
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
    end

    it 'excludes files matching any pattern' do
      config = Yard::Lint::Config.new do |c|
        c.exclude = ['vendor/**/*', 'spec/**/*']
      end

      result = Yard::Lint.run(path: test_dir, config:)

      file_paths = result.offenses.map { |o| o[:location] }
      expect(file_paths).not_to include(vendor_file)
      expect(file_paths).not_to include(spec_file)
      expect(file_paths).to include(lib_file)
    end
  end

  describe 'edge cases' do
    it 'handles patterns with curly braces (extglob)' do
      config = Yard::Lint::Config.new do |c|
        c.exclude = ['{vendor,spec}/**/*']
      end

      result = Yard::Lint.run(path: test_dir, config:)

      file_paths = result.offenses.map { |o| o[:location] }
      expect(file_paths).not_to include(vendor_file)
      expect(file_paths).to include(lib_file)
    end

    it 'handles single file exclusion by relative path' do
      config = Yard::Lint::Config.new do |c|
        c.exclude = ['lib/my_code.rb']
      end

      result = Yard::Lint.run(path: test_dir, config:)

      file_paths = result.offenses.map { |o| o[:location] }
      expect(file_paths).not_to include(lib_file)
    end
  end
end
