# frozen_string_literal: true

RSpec.describe Yard::Lint do
  describe 'VERSION' do
    it 'has a version number' do
      expect(Yard::Lint::VERSION).not_to be_nil
      expect(Yard::Lint::VERSION).to match(/\d+\.\d+\.\d+/)
    end
  end

  describe '.run' do
    let(:test_file) { '/tmp/test_lint.rb' }

    before do
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

    it 'returns a Result object' do
      result = described_class.run(path: test_file)

      expect(result).to be_a(Yard::Lint::Result)
    end

    it 'accepts a config object' do
      config = Yard::Lint::Config.new do |c|
        c.options = ['--private']
      end

      result = described_class.run(path: test_file, config: config)

      expect(result).to be_a(Yard::Lint::Result)
    end

    it 'filters excluded files' do
      config = Yard::Lint::Config.new do |c|
        c.exclude = ['/tmp/**/*']
      end

      result = described_class.run(path: test_file, config: config)

      # Should be clean since file is excluded
      expect(result.clean?).to be true
    end
  end

  describe '.load_config' do
    it 'loads config from specified file' do
      config_file = '/tmp/test-config.yml'
      File.write(config_file, "options:\n  - --private\n")

      config = described_class.load_config(config_file)

      expect(config.options).to eq(['--private'])

      FileUtils.rm_f(config_file)
    end

    it 'auto-loads config when no file specified' do
      allow(Yard::Lint::Config).to receive(:load).and_return(nil)

      config = described_class.load_config(nil)

      expect(config).to be_a(Yard::Lint::Config)
    end

    it 'returns new config when no file found' do
      allow(Yard::Lint::Config).to receive(:load).and_return(nil)

      config = described_class.load_config(nil)

      expect(config).to be_a(Yard::Lint::Config)
      expect(config.options).to eq([])
    end
  end

  describe '.expand_path' do
    let(:config) { Yard::Lint::Config.new }

    before do
      FileUtils.mkdir_p('/tmp/test_expand')
      File.write('/tmp/test_expand/test1.rb', '# test')
      File.write('/tmp/test_expand/test2.rb', '# test')
      File.write('/tmp/test_expand/readme.txt', 'not ruby')
    end

    after do
      FileUtils.rm_rf('/tmp/test_expand')
    end

    it 'expands directory to Ruby files' do
      files = described_class.expand_path('/tmp/test_expand', config)

      expect(files).to include('/tmp/test_expand/test1.rb')
      expect(files).to include('/tmp/test_expand/test2.rb')
      expect(files).not_to include('/tmp/test_expand/readme.txt')
    end

    it 'filters files based on exclusion patterns' do
      config.exclude = ['**/test2.rb']
      files = described_class.expand_path('/tmp/test_expand', config)

      expect(files).to include('/tmp/test_expand/test1.rb')
      expect(files).not_to include('/tmp/test_expand/test2.rb')
    end

    it 'handles single file path' do
      files = described_class.expand_path('/tmp/test_expand/test1.rb', config)

      expect(files).to eq(['/tmp/test_expand/test1.rb'])
    end

    it 'handles glob patterns' do
      files = described_class.expand_path('/tmp/test_expand/*.rb', config)

      expect(files.length).to eq(2)
      expect(files).to all(end_with('.rb'))
    end
  end
end
