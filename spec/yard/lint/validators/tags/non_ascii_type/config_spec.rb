# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::NonAsciiType::Config do
  describe '.id' do
    it 'returns :non_ascii_type' do
      expect(described_class.id).to eq(:non_ascii_type)
    end
  end

  describe '.defaults' do
    it 'has Enabled set to true' do
      expect(described_class.defaults['Enabled']).to be true
    end

    it 'has Severity set to warning' do
      expect(described_class.defaults['Severity']).to eq('warning')
    end

    it 'has ValidatedTags with param, option, return, yieldreturn, yieldparam' do
      expected_tags = %w[param option return yieldreturn yieldparam]
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
