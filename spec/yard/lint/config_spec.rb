# frozen_string_literal: true

require 'tmpdir'

RSpec.describe Yard::Lint::Config do
  describe '#initialize' do
    it 'sets default values' do
      config = described_class.new

      expect(config.options).to eq([])
      expect(config.validator_config('Tags/Order', 'EnforcedOrder')).to eq(Yard::Lint::Validators::Tags::Order::Config.defaults['EnforcedOrder'])
      expect(config.validator_config('Tags/InvalidTypes', 'ValidatedTags')).to eq(Yard::Lint::Validators::Tags::InvalidTypes::Config.defaults['ValidatedTags'])
      expect(config.validator_config('Tags/InvalidTypes', 'ExtraTypes')).to eq([])
      expect(config.exclude).to include('\.git', 'vendor/**/*', 'node_modules/**/*', 'spec/**/*', 'test/**/*')
      expect(config.fail_on_severity).to eq('warning')
      expect(config.validator_enabled?('Tags/ApiTags')).to be false
      expect(config.validator_config('Tags/ApiTags', 'AllowedApis')).to eq(Yard::Lint::Validators::Tags::ApiTags::Config.defaults['AllowedApis'])
      expect(config.validator_enabled?('Semantic/AbstractMethods')).to be true
      expect(config.validator_enabled?('Tags/OptionTags')).to be true
    end

    it 'accepts a block for configuration' do
      config = described_class.new do |c|
        c.options = ['--private']
        c.send(:set_validator_config, 'Tags/Order', 'EnforcedOrder', %w[param return])
        c.send(:set_validator_config, 'Tags/InvalidTypes', 'ExtraTypes', ['CustomType'])
        c.exclude = ['spec/**/*']
        c.fail_on_severity = 'error'
        c.send(:set_validator_config, 'Tags/ApiTags', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ApiTags', 'AllowedApis', %w[public private])
        c.send(:set_validator_config, 'Semantic/AbstractMethods', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/OptionTags', 'Enabled', true)
      end

      expect(config.options).to eq(['--private'])
      expect(config.validator_config('Tags/Order', 'EnforcedOrder')).to eq(%w[param return])
      expect(config.validator_config('Tags/InvalidTypes', 'ExtraTypes')).to eq(['CustomType'])
      expect(config.exclude).to eq(['spec/**/*'])
      expect(config.fail_on_severity).to eq('error')
      expect(config.validator_enabled?('Tags/ApiTags')).to be true
      expect(config.validator_config('Tags/ApiTags', 'AllowedApis')).to eq(%w[public private])
      expect(config.validator_enabled?('Semantic/AbstractMethods')).to be true
      expect(config.validator_enabled?('Tags/OptionTags')).to be true
    end
  end

  describe '.from_file' do
    let(:config_file) { '/tmp/test-yard-lint.yml' }

    after do
      FileUtils.rm_f(config_file)
    end

    it 'raises an error if file does not exist' do
      expect do
        described_class.from_file('/nonexistent/file.yml')
      end.to raise_error(Yard::Lint::Errors::ConfigFileNotFoundError, /Config file not found/)
    end

    it 'loads configuration from YAML file' do
      File.write(config_file, <<~YAML)
        AllValidators:
          YardOptions:
            - --private
            - --protected
          Exclude:
            - spec/**/*
            - vendor/**/*
          FailOnSeverity: error

        Tags/Order:
          EnforcedOrder:
            - param
            - return
            - raise

        Tags/InvalidTypes:
          ValidatedTags:
            - param
            - return
          ExtraTypes:
            - CustomType
            - MyType

        Tags/ApiTags:
          Enabled: true
          AllowedApis:
            - public
            - private

        Semantic/AbstractMethods:
          Enabled: true

        Tags/OptionTags:
          Enabled: true
      YAML

      config = described_class.from_file(config_file)

      expect(config.options).to eq(['--private', '--protected'])
      expect(config.validator_config('Tags/Order', 'EnforcedOrder')).to eq(%w[param return raise])
      expect(config.validator_config('Tags/InvalidTypes', 'ValidatedTags')).to eq(%w[param return])
      expect(config.validator_config('Tags/InvalidTypes', 'ExtraTypes'))
        .to eq(%w[CustomType MyType])
      expect(config.exclude).to eq(['spec/**/*', 'vendor/**/*'])
      expect(config.fail_on_severity).to eq('error')
      expect(config.validator_enabled?('Tags/ApiTags')).to be true
      expect(config.validator_config('Tags/ApiTags', 'AllowedApis')).to eq(%w[public private])
      expect(config.validator_enabled?('Semantic/AbstractMethods')).to be true
      expect(config.validator_enabled?('Tags/OptionTags')).to be true
    end

    it 'uses defaults for missing keys' do
      File.write(config_file, <<~YAML)
        AllValidators:
          YardOptions:
            - --private
      YAML

      config = described_class.from_file(config_file)

      expect(config.options).to eq(['--private'])
      expect(config.validator_config('Tags/Order', 'EnforcedOrder')).to eq(Yard::Lint::Validators::Tags::Order::Config.defaults['EnforcedOrder'])
      expect(config.exclude).to include('\.git', 'vendor/**/*', 'node_modules/**/*')
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
      # Hash-like access doesn't work for validator configs - use validator_config method
      expect(config.validator_config('Tags/Order', 'EnforcedOrder')).to eq(Yard::Lint::Validators::Tags::Order::Config.defaults['EnforcedOrder'])
    end

    it 'returns nil for non-existent attributes' do
      config = described_class.new

      expect(config[:nonexistent]).to be_nil
    end
  end

  describe 'edge cases' do
    it 'handles invalid severity levels gracefully' do
      config = described_class.new do |c|
        c.fail_on_severity = 'invalid'
      end

      expect(config.fail_on_severity).to eq('invalid')
    end

    it 'handles empty tags_order' do
      config = described_class.new do |c|
        c.send(:set_validator_config, 'Tags/Order', 'EnforcedOrder', [])
      end

      expect(config.validator_config('Tags/Order', 'EnforcedOrder')).to eq([])
    end

    it 'handles nil values in configuration' do
      config = described_class.new({ 'AllValidators' => { 'Exclude' => nil } })

      expect(config.exclude).to include('\.git', 'vendor/**/*', 'node_modules/**/*')
    end

    it 'returns correct validator severity' do
      config = described_class.new({
        'Tags/Order' => { 'Severity' => 'error' }
      })

      expect(config.validator_severity('Tags/Order')).to eq('error')
    end

    it 'returns department severity when validator severity not set' do
      config = described_class.new

      expect(config.validator_severity('Tags/Order')).to eq('convention')
    end

    it 'returns validator exclude patterns' do
      config = described_class.new({
        'Tags/Order' => { 'Exclude' => ['test/**/*'] }
      })

      expect(config.validator_exclude('Tags/Order')).to eq(['test/**/*'])
    end

    it 'returns empty array for validator without exclude patterns' do
      config = described_class.new

      expect(config.validator_exclude('Tags/Order')).to eq([])
    end

    it 'returns validator config value' do
      config = described_class.new({
        'Tags/Order' => { 'EnforcedOrder' => %w[param return] }
      })

      expect(config.validator_config('Tags/Order', 'EnforcedOrder')).to eq(%w[param return])
    end

    it 'returns nil for non-existent validator config key' do
      config = described_class.new

      expect(config.validator_config('Tags/Order', 'NonExistent')).to be_nil
    end
  end

  describe '.from_file with errors' do
    it 'raises ConfigFileNotFoundError for non-existent file' do
      expect { described_class.from_file('/non/existent/file.yml') }
        .to raise_error(Yard::Lint::Errors::ConfigFileNotFoundError, /Config file not found/)
    end
  end
end
