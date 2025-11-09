# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TypeSyntax::Config do
  describe '.id' do
    it 'returns :type_syntax' do
      expect(described_class.id).to eq(:type_syntax)
    end
  end

  describe '.defaults' do
    it 'has Enabled set to true' do
      expect(described_class.defaults['Enabled']).to be true
    end

    it 'has Severity set to warning' do
      expect(described_class.defaults['Severity']).to eq('warning')
    end

    it 'has ValidatedTags with param, option, return, yieldreturn' do
      expected_tags = %w[param option return yieldreturn]
      expect(described_class.defaults['ValidatedTags']).to eq(expected_tags)
    end

    it 'is frozen' do
      expect(described_class.defaults).to be_frozen
    end
  end

  describe 'inheritance' do
    it 'inherits from Validators::Config' do
      expect(described_class.superclass).to eq(Yard::Lint::Validators::Config)
    end
  end
end
