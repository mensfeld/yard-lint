# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::InvalidTypes::Result do
  let(:config) { Yard::Lint::Config.new }
  let(:parsed_data) { [] }
  let(:result) { described_class.new(parsed_data, config) }

  describe '#initialize' do
    it 'inherits from Results::Base' do
      expect(result).to be_a(Yard::Lint::Results::Base)
    end

    it 'stores config' do
      expect(result.instance_variable_get(:@config)).to eq(config)
    end
  end

  describe '#offenses' do
    it 'returns an array' do
      expect(result.offenses).to be_an(Array)
    end

    it 'handles empty parsed data' do
      expect(result.offenses).to eq([])
    end
  end

  describe 'class methods' do
    it 'defines default_severity' do
      expect(described_class).to respond_to(:default_severity)
    end

    it 'defines offense_type' do
      expect(described_class).to respond_to(:offense_type)
    end

    it 'defines offense_name' do
      expect(described_class).to respond_to(:offense_name)
    end
  end
end
