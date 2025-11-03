# frozen_string_literal: true

require 'tmpdir'

RSpec.describe Yard::Lint::Config do
  describe '#initialize' do
    it 'sets default values' do
      config = described_class.new

      expect(config.options).to eq([])
      expect(config.tags_order).to eq(described_class::DEFAULT_TAGS_ORDER)
      expect(config.invalid_tags_names).to eq(described_class::DEFAULT_INVALID_TAGS_NAMES)
      expect(config.extra_types).to eq([])
      expect(config.exclude).to eq(described_class::DEFAULT_EXCLUDE)
      expect(config.fail_on_severity).to eq('warning')
      expect(config.require_api_tags).to eq(false)
      expect(config.allowed_apis).to eq(described_class::DEFAULT_ALLOWED_APIS)
      expect(config.validate_abstract_methods).to eq(true)
      expect(config.validate_option_tags).to eq(true)
    end

    it 'accepts a block for configuration' do
      config = described_class.new do |c|
        c.options = ['--private']
        c.tags_order = %w[param return]
        c.extra_types = ['CustomType']
        c.exclude = ['spec/**/*']
        c.fail_on_severity = 'error'
        c.require_api_tags = true
        c.allowed_apis = %w[public private]
        c.validate_abstract_methods = true
        c.validate_option_tags = true
      end

      expect(config.options).to eq(['--private'])
      expect(config.tags_order).to eq(%w[param return])
      expect(config.extra_types).to eq(['CustomType'])
      expect(config.exclude).to eq(['spec/**/*'])
      expect(config.fail_on_severity).to eq('error')
      expect(config.require_api_tags).to eq(true)
      expect(config.allowed_apis).to eq(%w[public private])
      expect(config.validate_abstract_methods).to eq(true)
      expect(config.validate_option_tags).to eq(true)
    end
  end

  describe '.from_file' do
    let(:config_file) { '/tmp/test-yard-lint.yml' }

    after do
      File.delete(config_file) if File.exist?(config_file)
    end

    it 'raises an error if file does not exist' do
      expect do
        described_class.from_file('/nonexistent/file.yml')
      end.to raise_error(ArgumentError, /Config file not found/)
    end

    it 'loads configuration from YAML file' do
      File.write(config_file, <<~YAML)
        options:
          - --private
          - --protected
        tags_order:
          - param
          - return
          - raise
        invalid_tags_names:
          - param
          - return
        extra_types:
          - CustomType
          - MyType
        exclude:
          - spec/**/*
          - vendor/**/*
        fail_on_severity: error
        require_api_tags: true
        allowed_apis:
          - public
          - private
        validate_abstract_methods: true
        validate_option_tags: true
      YAML

      config = described_class.from_file(config_file)

      expect(config.options).to eq(['--private', '--protected'])
      expect(config.tags_order).to eq(%w[param return raise])
      expect(config.invalid_tags_names).to eq(%w[param return])
      expect(config.extra_types).to eq(%w[CustomType MyType])
      expect(config.exclude).to eq(['spec/**/*', 'vendor/**/*'])
      expect(config.fail_on_severity).to eq('error')
      expect(config.require_api_tags).to eq(true)
      expect(config.allowed_apis).to eq(%w[public private])
      expect(config.validate_abstract_methods).to eq(true)
      expect(config.validate_option_tags).to eq(true)
    end

    it 'uses defaults for missing keys' do
      File.write(config_file, <<~YAML)
        options:
          - --private
      YAML

      config = described_class.from_file(config_file)

      expect(config.options).to eq(['--private'])
      expect(config.tags_order).to eq(described_class::DEFAULT_TAGS_ORDER)
      expect(config.exclude).to eq(described_class::DEFAULT_EXCLUDE)
    end
  end

  describe '.load' do
    it 'returns nil if no config file is found' do
      allow(described_class).to receive(:find_config_file).and_return(nil)

      expect(described_class.load).to be_nil
    end

    it 'loads config file if found' do
      config_path = '/tmp/.yard-lint.yml'
      allow(described_class).to receive(:find_config_file).and_return(config_path)
      allow(File).to receive(:exist?).with(config_path).and_return(true)
      allow(YAML).to receive(:load_file).with(config_path).and_return({})

      config = described_class.load

      expect(config).to be_a(described_class)
    end
  end

  describe '.find_config_file' do
    it 'finds config file in current directory' do
      Dir.mktmpdir do |dir|
        config_file = File.join(dir, described_class::DEFAULT_CONFIG_FILE)
        File.write(config_file, '')

        expect(described_class.find_config_file(dir)).to eq(config_file)
      end
    end

    it 'finds config file in parent directory' do
      Dir.mktmpdir do |parent_dir|
        config_file = File.join(parent_dir, described_class::DEFAULT_CONFIG_FILE)
        File.write(config_file, '')

        child_dir = File.join(parent_dir, 'child')
        Dir.mkdir(child_dir)

        expect(described_class.find_config_file(child_dir)).to eq(config_file)
      end
    end

    it 'returns nil if no config file is found' do
      Dir.mktmpdir do |dir|
        expect(described_class.find_config_file(dir)).to be_nil
      end
    end
  end

  describe '#[]' do
    it 'allows hash-like access to attributes' do
      config = described_class.new

      expect(config[:options]).to eq([])
      expect(config[:tags_order]).to eq(described_class::DEFAULT_TAGS_ORDER)
    end

    it 'returns nil for non-existent attributes' do
      config = described_class.new

      expect(config[:nonexistent]).to be_nil
    end
  end
end
