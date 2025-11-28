# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result do
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

  describe 'class attributes' do
    it 'defines default_severity as convention' do
      expect(described_class.default_severity).to eq('convention')
    end

    it 'defines offense_type as line' do
      expect(described_class.offense_type).to eq('line')
    end

    it 'defines offense_name as BlankLineBeforeDefinition' do
      expect(described_class.offense_name).to eq('BlankLineBeforeDefinition')
    end
  end

  describe '#build_message' do
    let(:offense) do
      {
        location: 'lib/example.rb',
        line: 10,
        object_name: 'MyClass#process',
        violation_type: 'single',
        blank_count: 1
      }
    end

    it 'delegates to MessagesBuilder' do
      expect(result.build_message(offense)).to include('Blank line')
      expect(result.build_message(offense)).to include('MyClass#process')
    end
  end

  describe 'severity handling' do
    context 'with single blank line violation' do
      let(:parsed_data) do
        [
          {
            location: 'lib/example.rb',
            line: 10,
            object_name: 'MyClass#process',
            violation_type: 'single',
            blank_count: 1
          }
        ]
      end

      it 'uses default severity for single blank line' do
        expect(result.offenses.first[:severity]).to eq('convention')
      end
    end

    context 'with orphaned documentation violation' do
      let(:parsed_data) do
        [
          {
            location: 'lib/example.rb',
            line: 15,
            object_name: 'MyClass#execute',
            violation_type: 'orphaned',
            blank_count: 2
          }
        ]
      end

      it 'uses OrphanedSeverity for orphaned docs' do
        expect(result.offenses.first[:severity]).to eq('convention')
      end
    end
  end
end
