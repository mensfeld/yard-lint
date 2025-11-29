# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder do
  describe '.call' do
    context 'with single blank line violation' do
      let(:offense) do
        {
          location: 'lib/example.rb',
          line: 10,
          object_name: 'MyClass#process',
          violation_type: 'single',
          blank_count: 1
        }
      end

      it 'returns message for single blank line' do
        message = described_class.call(offense)

        expect(message).to eq("Blank line between documentation and definition for 'MyClass#process'")
      end
    end

    context 'with orphaned documentation violation' do
      let(:offense) do
        {
          location: 'lib/example.rb',
          line: 15,
          object_name: 'MyClass#execute',
          violation_type: 'orphaned',
          blank_count: 2
        }
      end

      it 'returns message for orphaned documentation' do
        message = described_class.call(offense)

        expect(message).to eq(
          "Documentation is orphaned (YARD ignores it due to blank lines) for 'MyClass#execute' (2 blank lines)"
        )
      end
    end

    context 'with orphaned documentation and 3 blank lines' do
      let(:offense) do
        {
          location: 'lib/example.rb',
          line: 20,
          object_name: 'MyClass#run',
          violation_type: 'orphaned',
          blank_count: 3
        }
      end

      it 'includes blank line count in message' do
        message = described_class.call(offense)

        expect(message).to include('3 blank lines')
      end
    end

    context 'with unknown violation type' do
      let(:offense) do
        {
          location: 'lib/example.rb',
          line: 5,
          object_name: 'MyClass#unknown',
          violation_type: 'unknown',
          blank_count: 1
        }
      end

      it 'returns generic message' do
        message = described_class.call(offense)

        expect(message).to eq("Blank line before definition for 'MyClass#unknown'")
      end
    end
  end

  describe '::ERROR_DESCRIPTIONS' do
    it 'contains single description' do
      expect(described_class::ERROR_DESCRIPTIONS).to have_key('single')
    end

    it 'contains orphaned description' do
      expect(described_class::ERROR_DESCRIPTIONS).to have_key('orphaned')
    end

    it 'is frozen' do
      expect(described_class::ERROR_DESCRIPTIONS).to be_frozen
    end
  end
end
