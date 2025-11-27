# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::InformalNotation::Result do
  describe 'class attributes' do
    it 'has default_severity set to warning' do
      expect(described_class.default_severity).to eq('warning')
    end

    it 'has offense_type set to line' do
      expect(described_class.offense_type).to eq('line')
    end

    it 'has offense_name set to InformalNotation' do
      expect(described_class.offense_name).to eq('InformalNotation')
    end
  end

  describe '#build_message' do
    it 'delegates to MessagesBuilder' do
      offense = {
        pattern: 'Note',
        replacement: '@note',
        line_text: 'Note: This is important'
      }

      allow(Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder).to receive(:call)
        .with(offense)
        .and_return('formatted message')

      result = described_class.new([])
      message = result.build_message(offense)

      expect(message).to eq('formatted message')
      expect(Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder).to have_received(:call)
        .with(offense)
    end
  end

  describe 'inheritance' do
    it 'inherits from Results::Base' do
      expect(described_class.superclass).to eq(Yard::Lint::Results::Base)
    end
  end
end
