# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ForbiddenTags::Config do
  describe 'class attributes' do
    it 'has id set to :forbidden_tags' do
      expect(described_class.id).to eq(:forbidden_tags)
    end

    it 'has defaults configured' do
      expect(described_class.defaults).to be_a(Hash)
      expect(described_class.defaults['Enabled']).to be(false)
      expect(described_class.defaults['Severity']).to eq('convention')
      expect(described_class.defaults['ForbiddenPatterns']).to eq([])
    end
  end

  describe 'inheritance' do
    it 'inherits from Validators::Config' do
      expect(described_class.superclass).to eq(Yard::Lint::Validators::Config)
    end
  end
end
