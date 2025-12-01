# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TagGroupSeparator::Result do
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
    it 'defines default_severity as convention' do
      expect(described_class.default_severity).to eq('convention')
    end

    it 'defines offense_type as method' do
      expect(described_class.offense_type).to eq('method')
    end

    it 'defines offense_name as MissingTagGroupSeparator' do
      expect(described_class.offense_name).to eq('MissingTagGroupSeparator')
    end
  end

  describe '#build_message' do
    let(:parsed_data) do
      [
        {
          location: 'lib/example.rb',
          line: 10,
          method_name: 'call',
          separators: 'param->return'
        }
      ]
    end

    it 'generates human-readable message' do
      offense = result.offenses.first
      expect(offense[:message]).to include('call')
      expect(offense[:message]).to include('param')
      expect(offense[:message]).to include('return')
    end
  end
end
