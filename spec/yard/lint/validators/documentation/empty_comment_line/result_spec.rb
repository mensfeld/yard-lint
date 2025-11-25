# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::EmptyCommentLine::Result do
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

    it 'defines offense_name as EmptyCommentLine' do
      expect(described_class.offense_name).to eq('EmptyCommentLine')
    end
  end

  describe '#build_message' do
    let(:offense) do
      {
        location: 'lib/example.rb',
        line: 5,
        object_line: 10,
        object_name: 'MyClass#process',
        violation_type: 'leading'
      }
    end

    it 'delegates to MessagesBuilder' do
      expect(result.build_message(offense)).to include('leading')
      expect(result.build_message(offense)).to include('MyClass#process')
    end
  end
end
