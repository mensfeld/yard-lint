# frozen_string_literal: true

RSpec.describe Yard::Lint::Runner do
  let(:selection) { ['lib/example.rb'] }
  let(:config) { Yard::Lint::Config.new }
  let(:runner) { described_class.new(selection, config) }

  describe '#initialize' do
    it 'stores selection as array' do
      expect(runner.selection).to eq(['lib/example.rb'])
    end

    it 'flattens nested arrays in selection' do
      nested_runner = described_class.new([['file1.rb'], 'file2.rb'], config)
      expect(nested_runner.selection).to eq(['file1.rb', 'file2.rb'])
    end

    it 'stores config' do
      expect(runner.config).to eq(config)
    end

    it 'uses default config when none provided' do
      default_runner = described_class.new(selection)
      expect(default_runner.config).to be_a(Yard::Lint::Config)
    end

    it 'creates result builder with config' do
      expect(runner.instance_variable_get(:@result_builder)).to be_a(Yard::Lint::ResultBuilder)
    end
  end

  describe '#run' do
    it 'returns an aggregate result object' do
      result = runner.run
      expect(result).to be_a(Yard::Lint::Results::Aggregate)
    end

    it 'orchestrates the validation process' do
      expect(runner).to receive(:run_validators).and_call_original
      expect(runner).to receive(:parse_results).and_call_original
      expect(runner).to receive(:build_result).and_call_original
      runner.run
    end
  end

  describe 'integration' do
    it 'processes enabled validators only' do
      custom_config = Yard::Lint::Config.new
      allow(custom_config).to receive(:validator_enabled?).and_return(false)
      runner = described_class.new(selection, custom_config)

      result = runner.run
      expect(result.count).to eq(0)
    end
  end
end
