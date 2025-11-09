# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::CollectionType::Config do
  describe 'class attributes' do
    it 'has id set to :collection_type' do
      expect(described_class.id).to eq(:collection_type)
    end

    it 'has defaults configured' do
      expect(described_class.defaults).to be_a(Hash)
      expect(described_class.defaults['Enabled']).to eq(true)
      expect(described_class.defaults['Severity']).to eq('convention')
      expect(described_class.defaults['ValidatedTags']).to eq(%w[param option return yieldreturn])
    end
  end

  describe 'inheritance' do
    it 'inherits from Validators::Config' do
      expect(described_class.superclass).to eq(Yard::Lint::Validators::Config)
    end
  end
end
