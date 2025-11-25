# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder do
  describe '.call' do
    context 'with leading violation' do
      let(:offense) do
        {
          location: 'lib/example.rb',
          line: 5,
          object_line: 10,
          object_name: 'MyClass#process',
          violation_type: 'leading'
        }
      end

      it 'returns message for leading empty comment line' do
        message = described_class.call(offense)

        expect(message).to eq("Empty leading comment line in documentation for 'MyClass#process'")
      end
    end

    context 'with trailing violation' do
      let(:offense) do
        {
          location: 'lib/example.rb',
          line: 9,
          object_line: 10,
          object_name: 'MyClass#execute',
          violation_type: 'trailing'
        }
      end

      it 'returns message for trailing empty comment line' do
        message = described_class.call(offense)

        expect(message).to eq("Empty trailing comment line in documentation for 'MyClass#execute'")
      end
    end

    context 'with unknown violation type' do
      let(:offense) do
        {
          location: 'lib/example.rb',
          line: 5,
          object_line: 10,
          object_name: 'MyClass#unknown',
          violation_type: 'unknown'
        }
      end

      it 'returns generic message' do
        message = described_class.call(offense)

        expect(message).to eq("Empty comment line in documentation for 'MyClass#unknown'")
      end
    end
  end

  describe '::ERROR_DESCRIPTIONS' do
    it 'contains leading description' do
      expect(described_class::ERROR_DESCRIPTIONS).to have_key('leading')
    end

    it 'contains trailing description' do
      expect(described_class::ERROR_DESCRIPTIONS).to have_key('trailing')
    end

    it 'is frozen' do
      expect(described_class::ERROR_DESCRIPTIONS).to be_frozen
    end
  end
end
