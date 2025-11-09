# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::MeaninglessTag::Config do
  describe 'class attributes' do
    it 'has id set to :meaningless_tag' do
      expect(described_class.id).to eq(:meaningless_tag)
    end

    it 'has defaults configured' do
      expect(described_class.defaults).to be_a(Hash)
      expect(described_class.defaults['Enabled']).to eq(true)
      expect(described_class.defaults['Severity']).to eq('warning')
      expect(described_class.defaults['CheckedTags']).to eq(%w[param option])
      expect(described_class.defaults['InvalidObjectTypes']).to eq(%w[class module constant])
    end
  end

  describe 'inheritance' do
    it 'inherits from Validators::Config' do
      expect(described_class.superclass).to eq(Yard::Lint::Validators::Config)
    end
  end
end
