# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ForbiddenTags::Result do
  describe 'class attributes' do
    it 'has default_severity set to convention' do
      expect(described_class.default_severity).to eq('convention')
    end

    it 'has offense_type set to tag' do
      expect(described_class.offense_type).to eq('tag')
    end

    it 'has offense_name set to ForbiddenTags' do
      expect(described_class.offense_name).to eq('ForbiddenTags')
    end
  end

  describe '#build_message' do
    it 'delegates to MessagesBuilder' do
      offense = {
        tag_name: 'return',
        types_text: 'void',
        pattern_types: 'void'
      }

      allow(Yard::Lint::Validators::Tags::ForbiddenTags::MessagesBuilder).to receive(:call)
        .with(offense)
        .and_return('formatted message')

      result = described_class.new([])
      message = result.send(:build_message, offense)

      expect(message).to eq('formatted message')
      expect(Yard::Lint::Validators::Tags::ForbiddenTags::MessagesBuilder).to have_received(:call)
        .with(offense)
    end
  end

  describe 'inheritance' do
    it 'inherits from Results::Base' do
      expect(described_class.superclass).to eq(Yard::Lint::Results::Base)
    end
  end
end
