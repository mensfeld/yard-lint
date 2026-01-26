# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ExampleStyle::Config do
  describe '.id' do
    it 'returns the validator identifier' do
      expect(described_class.id).to eq(:example_style)
    end
  end

  describe '.defaults' do
    it 'returns default configuration' do
      expect(described_class.defaults).to eq(
        'Enabled' => false,  # Opt-in validator
        'Severity' => 'convention',
        'Linter' => 'auto',
        'RespectProjectConfig' => true,
        'CustomConfigPath' => nil,
        'SkipPatterns' => [],
        'DisabledCops' => [
          'Style/FrozenStringLiteralComment',
          'Layout/TrailingWhitespace',
          'Layout/EndOfLine',
          'Layout/TrailingEmptyLines',
          'Metrics/MethodLength',
          'Metrics/AbcSize',
          'Metrics/CyclomaticComplexity',
          'Metrics/PerceivedComplexity'
        ]
      )
    end

    it 'returns frozen hash' do
      expect(described_class.defaults).to be_frozen
    end

    it 'is disabled by default (opt-in)' do
      expect(described_class.defaults['Enabled']).to be false
    end

    it 'has convention severity by default' do
      expect(described_class.defaults['Severity']).to eq('convention')
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
