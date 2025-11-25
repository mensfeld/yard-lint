# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::EmptyCommentLine::Config do
  describe '.id' do
    it 'returns the validator identifier' do
      expect(described_class.id).to eq(:empty_comment_line)
    end
  end

  describe '.defaults' do
    it 'returns default configuration' do
      expect(described_class.defaults).to eq(
        'Enabled' => true,
        'Severity' => 'convention',
        'EnabledPatterns' => {
          'Leading' => true,
          'Trailing' => true
        }
      )
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
