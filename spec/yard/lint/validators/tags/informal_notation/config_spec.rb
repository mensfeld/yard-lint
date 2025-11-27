# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::InformalNotation::Config do
  describe 'class attributes' do
    it 'has id set to :informal_notation' do
      expect(described_class.id).to eq(:informal_notation)
    end

    it 'has defaults configured' do
      expect(described_class.defaults).to be_a(Hash)
      expect(described_class.defaults['Enabled']).to be(true)
      expect(described_class.defaults['Severity']).to eq('warning')
      expect(described_class.defaults['CaseSensitive']).to be(false)
      expect(described_class.defaults['RequireStartOfLine']).to be(true)
    end

    it 'has default patterns configured' do
      patterns = described_class.defaults['Patterns']
      expect(patterns).to be_a(Hash)
      expect(patterns['Note']).to eq('@note')
      expect(patterns['Todo']).to eq('@todo')
      expect(patterns['TODO']).to eq('@todo')
      expect(patterns['FIXME']).to eq('@todo')
      expect(patterns['See']).to eq('@see')
      expect(patterns['See also']).to eq('@see')
      expect(patterns['Warning']).to eq('@deprecated')
      expect(patterns['Deprecated']).to eq('@deprecated')
      expect(patterns['Author']).to eq('@author')
      expect(patterns['Version']).to eq('@version')
      expect(patterns['Since']).to eq('@since')
      expect(patterns['Returns']).to eq('@return')
      expect(patterns['Raises']).to eq('@raise')
      expect(patterns['Example']).to eq('@example')
    end
  end

  describe 'inheritance' do
    it 'inherits from Validators::Config' do
      expect(described_class.superclass).to eq(Yard::Lint::Validators::Config)
    end
  end
end
