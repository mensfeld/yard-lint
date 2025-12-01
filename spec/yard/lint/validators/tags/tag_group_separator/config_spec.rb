# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TagGroupSeparator::Config do
  describe '.id' do
    it 'returns the validator identifier' do
      expect(described_class.id).to eq(:tag_group_separator)
    end
  end

  describe '.defaults' do
    it 'returns default configuration' do
      expect(described_class.defaults).to eq(
        'Enabled' => false,
        'Severity' => 'convention',
        'TagGroups' => {
          'param' => %w[param option],
          'return' => %w[return],
          'error' => %w[raise throws],
          'example' => %w[example],
          'meta' => %w[see note todo deprecated since version api],
          'yield' => %w[yield yieldparam yieldreturn]
        },
        'RequireAfterDescription' => false
      )
    end

    it 'returns frozen hash' do
      expect(described_class.defaults).to be_frozen
    end

    it 'is disabled by default' do
      expect(described_class.defaults['Enabled']).to be false
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
