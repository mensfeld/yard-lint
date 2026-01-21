# frozen_string_literal: true

RSpec.describe Yard::Lint::TodoGenerator do
  let(:test_dir) { Dir.mktmpdir('todo-generator-test') }
  let(:config) { Yard::Lint::Config.new }

  before { Dir.chdir(test_dir) }
  after do
    Dir.chdir('/')
    FileUtils.rm_rf(test_dir)
  end

  describe '.generate' do
    context 'with no violations' do
      it 'returns appropriate message without creating todo file' do
        # Create a clean Ruby file
        FileUtils.mkdir_p('lib')
        File.write('lib/clean.rb', <<~RUBY)
          # Documentation for Foo
          class Foo
          end
        RUBY

        result = described_class.generate(
          path: 'lib',
          config: config,
          force: false,
          exclude_limit: 15
        )

        expect(result[:message]).to include('No offenses found')
        expect(result[:offense_count]).to eq(0)
        expect(result[:validator_count]).to eq(0)
        expect(File.exist?('.yard-lint-todo.yml')).to be false
      end
    end

    context 'with violations' do
      before do
        FileUtils.mkdir_p('lib')
        File.write('lib/undocumented.rb', <<~RUBY)
          class Undocumented
            def method_without_docs(param)
            end
          end
        RUBY
      end

      it 'creates .yard-lint-todo.yml' do
        result = described_class.generate(
          path: 'lib',
          config: config,
          force: false,
          exclude_limit: 15
        )

        expect(File.exist?('.yard-lint-todo.yml')).to be true
        expect(result[:offense_count]).to be > 0
        expect(result[:validator_count]).to be > 0
      end

      it 'returns result with message and counts' do
        result = described_class.generate(
          path: 'lib',
          config: config,
          force: false,
          exclude_limit: 15
        )

        expect(result).to be_a(Hash)
        expect(result).to have_key(:message)
        expect(result).to have_key(:offense_count)
        expect(result).to have_key(:validator_count)
        expect(result[:message]).to include('Created .yard-lint-todo.yml')
      end

      it 'creates todo file with proper YAML structure' do
        described_class.generate(
          path: 'lib',
          config: config,
          force: false,
          exclude_limit: 15
        )

        expect(File.exist?('.yard-lint-todo.yml')).to be true

        content = File.read('.yard-lint-todo.yml')
        expect(content).to include('# This file was auto-generated')
        expect(content).to include('# To gradually fix violations')
        expect(content).to include('Exclude:')

        # Parse YAML to ensure it's valid
        yaml = YAML.load_file('.yard-lint-todo.yml')
        expect(yaml).to be_a(Hash)

        # Should have at least one validator with Exclude list
        validator_keys = yaml.keys
        expect(validator_keys.size).to be > 0

        validator_keys.each do |key|
          expect(yaml[key]).to have_key('Exclude')
          expect(yaml[key]['Exclude']).to be_an(Array)
        end
      end

      it 'creates or updates main config to inherit from todo file' do
        described_class.generate(
          path: 'lib',
          config: config,
          force: false,
          exclude_limit: 15
        )

        expect(File.exist?('.yard-lint.yml')).to be true

        config_content = YAML.load_file('.yard-lint.yml')
        expect(config_content['inherit_from']).to include('.yard-lint-todo.yml')
      end

      context 'when .yard-lint.yml already exists' do
        before do
          File.write('.yard-lint.yml', <<~YAML)
            AllValidators:
              Severity: warning
          YAML
        end

        it 'adds inherit_from to existing config' do
          described_class.generate(
            path: 'lib',
            config: config,
            force: false,
            exclude_limit: 15
          )

          config_content = YAML.load_file('.yard-lint.yml')
          expect(config_content['inherit_from']).to include('.yard-lint-todo.yml')
          expect(config_content['AllValidators']).to eq({ 'Severity' => 'warning' })
        end

        it 'does not duplicate inherit_from entry' do
          # Run twice
          described_class.generate(
            path: 'lib',
            config: config,
            force: true,
            exclude_limit: 15
          )

          described_class.generate(
            path: 'lib',
            config: config,
            force: true,
            exclude_limit: 15
          )

          config_content = YAML.load_file('.yard-lint.yml')
          inherit_count = config_content['inherit_from'].count('.yard-lint-todo.yml')
          expect(inherit_count).to eq(1)
        end
      end
    end

    context 'when todo file already exists' do
      before do
        FileUtils.mkdir_p('lib')
        File.write('lib/test.rb', <<~RUBY)
          class Test
          end
        RUBY
        File.write('.yard-lint-todo.yml', '# existing')
      end

      it 'raises TodoFileExistsError without force flag' do
        expect do
          described_class.generate(
            path: 'lib',
            config: config,
            force: false,
            exclude_limit: 15
          )
        end.to raise_error(Yard::Lint::Errors::TodoFileExistsError)
      end

      it 'overwrites with force flag' do
        result = described_class.generate(
          path: 'lib',
          config: config,
          force: true,
          exclude_limit: 15
        )

        expect(result).to be_a(Hash)
        content = File.read('.yard-lint-todo.yml')
        expect(content).not_to eq('# existing')
        expect(content).to include('# This file was auto-generated')
      end
    end

    context 'with custom exclude_limit' do
      it 'passes limit to PathGrouper' do
        FileUtils.mkdir_p('lib')

        # Create multiple files to trigger grouping logic
        20.times do |i|
          File.write("lib/file_#{i}.rb", <<~RUBY)
            class File#{i}
            end
          RUBY
        end

        # Mock PathGrouper to verify limit is passed
        allow(Yard::Lint::PathGrouper).to receive(:group).and_call_original

        described_class.generate(
          path: 'lib',
          config: config,
          force: false,
          exclude_limit: 10
        )

        # Verify PathGrouper was called with custom limit
        expect(Yard::Lint::PathGrouper).to have_received(:group).with(anything, limit: 10).at_least(:once)
      end
    end

    context 'with violations from multiple validators' do
      before do
        FileUtils.mkdir_p('lib')
        File.write('lib/multi.rb', <<~RUBY)
          class Multi
            # @param invalid
            def foo(bar)
            end

            def undocumented
            end
          end
        RUBY
      end

      it 'groups violations by validator' do
        described_class.generate(
          path: 'lib',
          config: config,
          force: false,
          exclude_limit: 15
        )

        yaml = YAML.load_file('.yard-lint-todo.yml')

        # Should have multiple validators
        expect(yaml.keys.size).to be > 0

        # Each validator should have Exclude list
        yaml.each do |validator_name, validator_config|
          expect(validator_name).to include('/')
          expect(validator_config).to have_key('Exclude')
        end
      end
    end
  end

  describe '#make_relative_path' do
    it 'converts absolute path to relative' do
      generator = described_class.new(
        path: '.',
        config: config,
        force: false,
        exclude_limit: 15
      )

      absolute = File.join(Dir.pwd, 'lib', 'foo.rb')
      relative = generator.send(:make_relative_path, absolute)

      expect(relative).to eq('lib/foo.rb')
    end

    it 'keeps relative path unchanged' do
      generator = described_class.new(
        path: '.',
        config: config,
        force: false,
        exclude_limit: 15
      )

      relative = 'lib/foo.rb'
      result = generator.send(:make_relative_path, relative)

      expect(result).to eq(relative)
    end
  end
end
