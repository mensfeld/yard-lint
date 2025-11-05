# frozen_string_literal: true

RSpec.describe Yard::Lint::Parsers::Base do
  let(:parser_class) do
    Class.new(described_class) do
      self.regexps = {
        test: /(?<value>\d+)/
      }.freeze
    end
  end

  let(:parser) { parser_class.new }

  describe '.regexps' do
    it 'allows setting class-level regexps' do
      expect(parser_class.regexps).to have_key(:test)
    end

    it 'can be accessed via instance' do
      expect(parser.class.regexps).to eq(parser_class.regexps)
    end
  end

  describe '#match' do
    it 'extracts captures using named regexp' do
      result = parser.match('Value: 123', :test)
      expect(result).to eq(['123'])
    end

    it 'returns empty array when no match' do
      result = parser.match('No numbers here', :test)
      expect(result).to eq([])
    end

    it 'returns captures from matched groups' do
      result = parser.match('42', :test)
      expect(result).to include('42')
    end
  end

  describe 'inheritance' do
    it 'can be subclassed' do
      subclass = Class.new(described_class)
      expect(subclass.new).to be_a(described_class)
    end
  end
end
