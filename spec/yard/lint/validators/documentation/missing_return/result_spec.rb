# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::MissingReturn::Result do
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

    context 'with parsed data' do
      let(:parsed_data) do
        [
          {
            location: 'lib/example.rb',
            line: 10,
            element: 'Calculator#add'
          }
        ]
      end

      it 'builds offenses from parsed data' do
        offenses = result.offenses
        expect(offenses).not_to be_empty
        expect(offenses.first[:location]).to eq('lib/example.rb')
        expect(offenses.first[:location_line]).to eq(10)
        expect(offenses.first[:name]).to eq('MissingReturnTag')
      end

      it 'includes message from MessagesBuilder' do
        offenses = result.offenses
        expect(offenses.first[:message]).to include('Missing @return tag for `Calculator#add`')
      end

      it 'sets offense type to line' do
        offenses = result.offenses
        expect(offenses.first[:type]).to eq('line')
      end

      it 'sets default severity to warning' do
        offenses = result.offenses
        expect(offenses.first[:severity]).to eq('warning')
      end
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

    it 'returns warning as default_severity' do
      expect(described_class.default_severity).to eq('warning')
    end

    it 'returns line as offense_type' do
      expect(described_class.offense_type).to eq('line')
    end

    it 'returns MissingReturnTag as offense_name' do
      expect(described_class.offense_name).to eq('MissingReturnTag')
    end
  end

  describe '#build_message' do
    let(:offense) { { element: 'Example#method' } }

    it 'delegates to MessagesBuilder' do
      allow(Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder)
        .to receive(:call).and_call_original

      result.build_message(offense)

      expect(Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder)
        .to have_received(:call).with(offense)
    end
  end
end
