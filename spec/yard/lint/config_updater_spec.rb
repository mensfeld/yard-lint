# frozen_string_literal: true

RSpec.describe Yard::Lint::ConfigUpdater do
  let(:fixtures_dir) { File.expand_path('../../fixtures', __dir__) }
  let(:config_path) { File.join(fixtures_dir, '.yard-lint.yml') }

  before do
    FileUtils.mkdir_p(fixtures_dir)
  end

  after do
    FileUtils.rm_f(config_path)
  end

  describe '.update' do
    context 'when config file does not exist' do
      it 'raises ConfigFileNotFoundError' do
        expect { described_class.update(path: config_path) }
          .to raise_error(Yard::Lint::Errors::ConfigFileNotFoundError, /Config file not found/)
      end

      it 'suggests using --init' do
        expect { described_class.update(path: config_path) }
          .to raise_error(Yard::Lint::Errors::ConfigFileNotFoundError, /Use --init to create one/)
      end
    end

    context 'when config file exists' do
      context 'with all current validators present' do
        before do
          template_path = File.join(Yard::Lint::ConfigUpdater::TEMPLATES_DIR, 'default_config.yml')
          FileUtils.cp(template_path, config_path)
        end

        it 'reports no changes needed' do
          result = described_class.update(path: config_path)

          expect(result[:added]).to be_empty
          expect(result[:removed]).to be_empty
        end

        it 'returns all validators as preserved' do
          result = described_class.update(path: config_path)

          expect(result[:preserved]).to eq(Yard::Lint::ConfigLoader::ALL_VALIDATORS.sort)
        end
      end

      context 'with missing validators' do
        before do
          File.write(config_path, <<~YAML)
            AllValidators:
              Exclude:
                - 'vendor/**/*'

            Documentation/UndocumentedObjects:
              Enabled: true
              Severity: error
          YAML
        end

        it 'adds new validators with default config' do
          result = described_class.update(path: config_path)

          expect(result[:added]).to include('Tags/Order')
          expect(result[:added]).to include('Tags/TypeSyntax')
        end

        it 'preserves existing validators' do
          result = described_class.update(path: config_path)

          expect(result[:preserved]).to eq(['Documentation/UndocumentedObjects'])
        end

        it 'preserves user settings for existing validators' do
          described_class.update(path: config_path)

          updated = YAML.load_file(config_path)
          expect(updated['Documentation/UndocumentedObjects']['Severity']).to eq('error')
        end

        it 'writes valid YAML' do
          described_class.update(path: config_path)

          expect { YAML.load_file(config_path) }.not_to raise_error
        end
      end

      context 'with obsolete validators' do
        before do
          # Start with a template and add an obsolete validator
          template_path = File.join(Yard::Lint::ConfigUpdater::TEMPLATES_DIR, 'default_config.yml')
          template_content = File.read(template_path)
          obsolete_content = template_content + <<~YAML

            Obsolete/FakeValidator:
              Enabled: true
              Severity: warning
          YAML
          File.write(config_path, obsolete_content)
        end

        it 'removes obsolete validators' do
          result = described_class.update(path: config_path)

          expect(result[:removed]).to eq(['Obsolete/FakeValidator'])
        end

        it 'does not include obsolete validators in output' do
          described_class.update(path: config_path)

          updated = YAML.load_file(config_path)
          expect(updated).not_to have_key('Obsolete/FakeValidator')
        end
      end

      context 'with partial validator config' do
        before do
          File.write(config_path, <<~YAML)
            AllValidators:
              Exclude: []

            Tags/Order:
              Enabled: false
          YAML
        end

        it 'merges with template defaults' do
          described_class.update(path: config_path)

          updated = YAML.load_file(config_path)

          # User setting preserved
          expect(updated['Tags/Order']['Enabled']).to be false
          # Template default merged in
          expect(updated['Tags/Order']['EnforcedOrder']).to be_an(Array)
          expect(updated['Tags/Order']['Description']).to be_a(String)
        end
      end

      context 'with empty config file' do
        before do
          File.write(config_path, '')
        end

        it 'adds all validators' do
          result = described_class.update(path: config_path)

          expect(result[:added].size).to eq(Yard::Lint::ConfigLoader::ALL_VALIDATORS.size)
          expect(result[:preserved]).to be_empty
        end
      end

      context 'with strict mode' do
        before do
          File.write(config_path, <<~YAML)
            AllValidators:
              Exclude: []

            Documentation/UndocumentedObjects:
              Enabled: true
          YAML
        end

        it 'uses strict template defaults for new validators' do
          described_class.update(path: config_path, strict: true)

          updated = YAML.load_file(config_path)

          # New validators should use strict template
          expect(updated['Tags/Order']).to be_a(Hash)
        end
      end

      context 'with YAML output format' do
        before do
          File.write(config_path, <<~YAML)
            AllValidators:
              Exclude: []
          YAML
        end

        it 'includes header comments' do
          described_class.update(path: config_path)

          content = File.read(config_path)
          expect(content).to include('# YARD-Lint Configuration')
        end

        it 'includes category comments' do
          described_class.update(path: config_path)

          content = File.read(config_path)
          expect(content).to include('# Documentation validators')
          expect(content).to include('# Tags validators')
          expect(content).to include('# Warnings validators')
          expect(content).to include('# Semantic validators')
        end

        it 'groups validators by category' do
          described_class.update(path: config_path)

          content = File.read(config_path)

          # Documentation validators should come before Tags validators
          doc_pos = content.index('Documentation/UndocumentedObjects:')
          tags_pos = content.index('Tags/Order:')
          expect(doc_pos).to be < tags_pos
        end

        it 'preserves AllValidators section' do
          described_class.update(path: config_path)

          updated = YAML.load_file(config_path)
          expect(updated).to have_key('AllValidators')
        end
      end
    end
  end

  describe '#initialize' do
    it 'uses default path when none provided' do
      Dir.chdir(fixtures_dir) do
        File.write('.yard-lint.yml', 'AllValidators: {}')
        updater = described_class.new
        expect { updater.update }.not_to raise_error
        File.delete('.yard-lint.yml')
      end
    end

    it 'uses provided path' do
      custom_path = File.join(fixtures_dir, 'custom_config.yml')
      File.write(custom_path, 'AllValidators: {}')

      result = described_class.update(path: custom_path)

      expect(result).to be_a(Hash)
      File.delete(custom_path)
    end
  end
end
