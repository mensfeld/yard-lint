# frozen_string_literal: true

RSpec.describe Yard::Lint::ConfigGenerator do
  describe '.generate' do
    # Use a temporary directory to avoid deleting the project's .yard-lint.yml
    let(:temp_dir) { Dir.mktmpdir }
    let(:config_path) { File.join(temp_dir, '.yard-lint.yml') }
    let(:original_dir) { Dir.pwd }

    around do |example|
      # Change to temp directory for these tests
      Dir.chdir(temp_dir) do
        example.run
      end
      # Clean up temp directory after test
      FileUtils.rm_rf(temp_dir)
    end

    context 'when config file does not exist' do
      it 'creates .yard-lint.yml file' do
        expect(File.exist?(config_path)).to be false

        result = described_class.generate

        expect(result).to be true
        expect(File.exist?(config_path)).to be true
      end

      it 'creates file with YARD-Lint configuration header' do
        described_class.generate

        content = File.read(config_path)
        expect(content).to include('# YARD-Lint Configuration')
        expect(content).to include('# See https://github.com/mensfeld/yard-lint for documentation')
      end

      it 'creates file with AllValidators section' do
        described_class.generate

        content = File.read(config_path)
        expect(content).to include('AllValidators:')
        expect(content).to include('YardOptions:')
        expect(content).to include('Exclude:')
        expect(content).to include('FailOnSeverity: warning')
      end

      it 'creates file with all discovered validator configurations' do
        described_class.generate

        content = File.read(config_path)

        # Dynamically check all validators from ConfigLoader
        Yard::Lint::ConfigLoader::ALL_VALIDATORS.each do |validator_name|
          expect(content).to include("#{validator_name}:"),
            "Expected config to include #{validator_name}"
        end
      end

      it 'creates file with default exclusions' do
        described_class.generate

        content = File.read(config_path)
        expect(content).to include("- '\\.git'")
        expect(content).to include("- 'vendor/**/*'")
        expect(content).to include("- 'node_modules/**/*'")
        expect(content).to include("- 'spec/**/*'")
        expect(content).to include("- 'test/**/*'")
      end

      it 'creates file with YARD options' do
        described_class.generate

        content = File.read(config_path)
        expect(content).to include('- --private')
        expect(content).to include('- --protected')
      end
    end

    context 'when config file already exists' do
      before do
        File.write(config_path, '# Existing config')
      end

      it 'returns false without overwriting' do
        result = described_class.generate

        expect(result).to be false
        expect(File.read(config_path)).to eq('# Existing config')
      end

      context 'with force: true' do
        it 'overwrites existing file' do
          result = described_class.generate(force: true)

          expect(result).to be true
          content = File.read(config_path)
          expect(content).to include('# YARD-Lint Configuration')
          expect(content).not_to eq('# Existing config')
        end
      end
    end

    context 'when validating generated config' do
      it 'generates valid YAML' do
        described_class.generate

        expect { YAML.load_file(config_path) }.not_to raise_error
      end

      it 'generates parseable config' do
        described_class.generate

        config_hash = YAML.load_file(config_path)
        expect(config_hash).to be_a(Hash)
        expect(config_hash).to have_key('AllValidators')
        expect(config_hash['AllValidators']).to have_key('YardOptions')
        expect(config_hash['AllValidators']).to have_key('Exclude')
        expect(config_hash['AllValidators']).to have_key('FailOnSeverity')
      end
    end
  end
end
