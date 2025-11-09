# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TagTypePosition::Result do
  describe 'class attributes' do
    it 'has default_severity set to convention' do
      expect(described_class.default_severity).to eq('convention')
    end

    it 'has offense_type set to style' do
      expect(described_class.offense_type).to eq('style')
    end

    it 'has offense_name set to TagTypePosition' do
      expect(described_class.offense_name).to eq('TagTypePosition')
    end
  end

  describe '#build_message' do
    it 'delegates to MessagesBuilder' do
      offense = {
        tag_name: 'param',
        param_name: 'name',
        type_info: 'String',
        detected_style: 'type_after_name'
      }

      allow(Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder)
        .to receive(:call)
        .with(offense)
        .and_return('formatted message')

      result = described_class.new([])
      message = result.build_message(offense)

      expect(message)
        .to eq('formatted message')
      expect(Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder)
        .to have_received(:call)
        .with(offense)
    end
  end

  describe 'inheritance' do
    it 'inherits from Results::Base' do
      expect(described_class.superclass).to eq(Yard::Lint::Results::Base)
    end
  end
end
