# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::UndocumentedObjects::Config do
  describe '.id' do
    it 'returns the validator identifier' do
      expect(described_class.id).to eq(:undocumented_objects)
    end
  end

  describe '.defaults' do
    it 'returns default configuration' do
      expect(described_class.defaults).to eq(
        'Enabled' => true,
        'Severity' => 'warning',
        'AllowEmptyInitialize' => true
      )
    end

    it 'returns frozen hash' do
      expect(described_class.defaults).to be_frozen
    end
  end

  describe '.combines_with' do
    it 'combines with UndocumentedBooleanMethods validator' do
      expect(described_class.combines_with).to eq(['Documentation/UndocumentedBooleanMethods'])
    end

    it 'returns frozen array' do
      expect(described_class.combines_with).to be_frozen
    end
  end

  describe 'inheritance' do
    it 'inherits from base Config class' do
      expect(described_class.superclass).to eq(Yard::Lint::Validators::Config)
    end
  end
end
