# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::MissingReturn::Config do
  describe '.id' do
    it 'returns the validator identifier' do
      expect(described_class.id).to eq(:missing_return)
    end
  end

  describe '.defaults' do
    it 'returns default configuration' do
      expect(described_class.defaults).to eq(
        'Enabled' => false,
        'Severity' => 'warning',
        'ExcludedMethods' => ['initialize']
      )
    end

    it 'returns frozen hash' do
      expect(described_class.defaults).to be_frozen
    end

    it 'disables validator by default (opt-in)' do
      expect(described_class.defaults['Enabled']).to be false
    end

    it 'excludes initialize methods by default' do
      expect(described_class.defaults['ExcludedMethods']).to include('initialize')
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
