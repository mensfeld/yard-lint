# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::Order::Parser do
  let(:parser) { described_class.new }

  describe '#initialize' do
    it 'inherits from parser base class' do
      expect(parser).to be_a(Yard::Lint::Parsers::Base)
    end
  end

  describe '#call' do
    it 'parses input and returns array' do
      result = parser.call('')
      expect(result).to be_an(Array)
    end

    it 'handles empty input' do
      result = parser.call('')
      expect(result).to eq([])
    end
  end
end
