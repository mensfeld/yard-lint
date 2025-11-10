# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::RedundantParamDescription::Config do
  describe '.id' do
    it 'returns the validator identifier' do
      expect(described_class.id).to eq(:redundant_param_description)
    end
  end

  describe '.defaults' do
    it 'returns default configuration' do
      defaults = described_class.defaults

      expect(defaults['Enabled']).to be true
      expect(defaults['Severity']).to eq('convention')
      expect(defaults['CheckedTags']).to eq(%w[param option])
      expect(defaults['Articles']).to eq(%w[The the A a An an])
      expect(defaults['MaxRedundantWords']).to eq(6)
      expect(defaults['MinMeaningfulLength']).to eq(15)
      expect(defaults['GenericTerms']).to eq(%w[object instance value data item element])
    end

    it 'includes all pattern toggles' do
      patterns = described_class.defaults['EnabledPatterns']

      expect(patterns['ArticleParam']).to be true
      expect(patterns['PossessiveParam']).to be true
      expect(patterns['TypeRestatement']).to be true
      expect(patterns['ParamToVerb']).to be true
      expect(patterns['IdPattern']).to be true
      expect(patterns['DirectionalDate']).to be true
      expect(patterns['TypeGeneric']).to be true
    end

    it 'returns frozen hash' do
      expect(described_class.defaults).to be_frozen
    end
  end

  describe '.combines_with' do
    it 'returns empty array for standalone validator' do
      expect(described_class.combines_with).to eq([])
    end
  end

  describe 'inheritance' do
    it 'inherits from base Config class' do
      expect(described_class.superclass).to eq(Yard::Lint::Validators::Config)
    end
  end
end
