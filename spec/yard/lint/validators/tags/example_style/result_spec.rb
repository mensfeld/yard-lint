# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ExampleStyle::Result do
  describe 'class attributes' do
    it 'has convention default severity' do
      expect(described_class.default_severity).to eq('convention')
    end

    it 'has line offense type' do
      expect(described_class.offense_type).to eq('line')
    end

    it 'has ExampleStyleOffense as offense name' do
      expect(described_class.offense_name).to eq('ExampleStyleOffense')
    end
  end

  describe '#initialize' do
    it 'inherits from result base class' do
      result = described_class.new([])
      expect(result).to be_a(Yard::Lint::Results::Base)
    end

    it 'builds offenses from parsed data' do
      parsed_data = [
        {
          name: 'ExampleStyle',
          object_name: 'User#initialize',
          example_name: 'Basic usage',
          cop_name: 'Style/StringLiterals',
          message: 'Prefer single-quoted strings',
          location: 'lib/user.rb',
          line: 10
        }
      ]

      result = described_class.new(parsed_data)
      expect(result.offenses.length).to eq(1)
      expect(result.offenses.first[:severity]).to eq('convention')
      expect(result.offenses.first[:name]).to eq('ExampleStyle')
    end

    it 'respects configured severity from config' do
      parsed_data = [
        {
          name: 'ExampleStyle',
          object_name: 'User#initialize',
          example_name: 'Basic usage',
          cop_name: 'Style/StringLiterals',
          message: 'Prefer single-quoted strings',
          location: 'lib/user.rb',
          line: 10
        }
      ]

      config = double('config')
      allow(config).to receive(:validator_severity).with('Tags/ExampleStyle').and_return('warning')

      result = described_class.new(parsed_data, config)
      expect(result.offenses.first[:severity]).to eq('warning')
    end
  end

  describe '#build_message' do
    it 'delegates to MessagesBuilder' do
      parsed_data = [
        {
          name: 'ExampleStyle',
          object_name: 'User#initialize',
          example_name: 'Basic usage',
          cop_name: 'Style/StringLiterals',
          message: 'Prefer single-quoted strings',
          location: 'lib/user.rb',
          line: 10
        }
      ]

      result = described_class.new(parsed_data)
      offense = result.offenses.first

      expect(offense[:message]).to include('User#initialize')
      expect(offense[:message]).to include('Style/StringLiterals')
      expect(offense[:message]).to include('Prefer single-quoted strings')
    end
  end
end
