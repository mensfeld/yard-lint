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

  describe '.in_process' do
    let(:validator_class) do
      Class.new(described_class) do
        in_process visibility: :all
      end
    end

    it 'marks the validator as in_process enabled' do
      expect(validator_class.in_process?).to be true
    end

    it 'stores the visibility setting' do
      expect(validator_class.in_process_visibility).to eq(:all)
    end
  end

  describe '.in_process?' do
    it 'returns false by default' do
      expect(described_class.in_process?).to be false
    end
  end

  describe '.validator_name' do
    let(:named_class) do
      Class.new(described_class)
    end

    it 'returns nil for base class' do
      expect(described_class.validator_name).to be_nil
    end

    it 'extracts name from valid namespace' do
      stub_const('Yard::Lint::Validators::Tags::Order::Validator', named_class)
      expect(named_class.validator_name).to eq('Tags/Order')
    end
  end

  describe '#in_process_query' do
    it 'raises NotImplementedError by default' do
      object = instance_double(YARD::CodeObjects::Base)
      collector = instance_double(Yard::Lint::Executor::ResultCollector)
      expect { validator.in_process_query(object, collector) }.to raise_error(NotImplementedError)
    end
  end

  describe '#config_or_default' do
    let(:concrete_validator_class) do
      Class.new(described_class) do
        # Fake namespace for testing: Yard::Lint::Validators::Tags::TestValidator::Validator
        def self.name
          'Yard::Lint::Validators::Tags::TestValidator::Validator'
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
      it 'returns the default value' do
        allow(config).to receive(:validator_config)
          .with('Tags/TestValidator', 'SomeKey')
          .and_return(nil)

        # Create a mock Config class with defaults
        config_class = Class.new do
          def self.defaults
            { 'SomeKey' => 'default_value' }
          end
        end
        stub_const('Yard::Lint::Validators::Tags::TestValidator::Config', config_class)

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
        end
      end

      let(:invalid_validator) { invalid_validator_class.new(config, selection) }

      it 'returns nil when no Config class exists' do
        result = invalid_validator.send(:config_or_default, 'SomeKey')
        expect(result).to be_nil
      end
    end
  end
end
