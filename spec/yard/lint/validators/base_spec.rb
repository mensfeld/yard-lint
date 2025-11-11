# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Base do
  let(:config) { Yard::Lint::Config.new }
  let(:selection) { ['lib/example.rb'] }
  let(:validator) { described_class.new(config, selection) }

  describe '#initialize' do
    it 'stores config' do
      expect(validator.config).to eq(config)
    end

    it 'stores selection' do
      expect(validator.selection).to eq(selection)
    end
  end

  describe '.command_cache' do
    it 'returns a CommandCache instance' do
      expect(described_class.command_cache).to be_a(Yard::Lint::CommandCache)
    end

    it 'returns same instance on subsequent calls' do
      cache1 = described_class.command_cache
      cache2 = described_class.command_cache
      expect(cache1).to equal(cache2)
    end
  end

  describe '.reset_command_cache!' do
    it 'resets the command cache' do
      old_cache = described_class.command_cache
      described_class.reset_command_cache!
      new_cache = described_class.command_cache
      expect(new_cache).not_to equal(old_cache)
    end
  end

  describe '.clear_yard_database!' do
    it 'clears YARD database files' do
      expect { described_class.clear_yard_database! }.not_to raise_error
    end
  end

  describe '#call' do
    let(:concrete_validator_class) do
      Class.new(described_class) do
        private

        def yard_cmd(_dir, _escaped_file_names)
          raw('test output', '', 0)
        end
      end
    end

    it 'returns raw hash with stdout, stderr, exit_code' do
      concrete_validator = concrete_validator_class.new(config, selection)
      result = concrete_validator.call
      expect(result).to be_a(Hash)
      expect(result).to have_key(:stdout)
      expect(result).to have_key(:stderr)
      expect(result).to have_key(:exit_code)
    end

    it 'returns empty result when selection is empty' do
      empty_validator = concrete_validator_class.new(config, [])
      result = empty_validator.call
      expect(result[:stdout]).to eq('')
    end
  end

  describe '#config_or_default' do
    let(:concrete_validator_class) do
      Class.new(described_class) do
        # Fake namespace for testing: Yard::Lint::Validators::Tags::TestValidator
        def self.name
          'Yard::Lint::Validators::Tags::TestValidator'
        end

        private

        def yard_cmd(_dir, _escaped_file_names)
          raw('test output', '', 0)
        end
      end
    end

    let(:validator) { concrete_validator_class.new(config, selection) }

    context 'when config value exists' do
      before do
        allow(config).to receive(:validator_config)
          .with('Tags/TestValidator', 'SomeKey')
          .and_return('configured_value')
      end

      it 'returns the configured value' do
        result = validator.send(:config_or_default, 'SomeKey')
        expect(result).to eq('configured_value')
      end
    end

    context 'when config value is nil' do
      before do
        allow(config).to receive(:validator_config)
          .with('Tags/TestValidator', 'SomeKey')
          .and_return(nil)
        allow(Yard::Lint::Validators::Tags::TestValidator::Config).to receive(:defaults)
          .and_return('SomeKey' => 'default_value')
      end

      it 'returns the default value' do
        result = validator.send(:config_or_default, 'SomeKey')
        expect(result).to eq('default_value')
      end
    end

    context 'when validator name cannot be extracted' do
      let(:invalid_validator_class) do
        Class.new(described_class) do
          def self.name
            'InvalidClassName'
          end

          private

          def yard_cmd(_dir, _escaped_file_names)
            raw('test output', '', 0)
          end
        end
      end

      let(:invalid_validator) { invalid_validator_class.new(config, selection) }

      it 'returns the default value from Config.defaults' do
        stub_const('Yard::Lint::Config', Class.new do
          def self.defaults
            { 'SomeKey' => 'global_default' }
          end
        end)

        result = invalid_validator.send(:config_or_default, 'SomeKey')
        expect(result).to eq('global_default')
      end
    end
  end
end
