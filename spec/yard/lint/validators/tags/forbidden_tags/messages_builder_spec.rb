# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ForbiddenTags::MessagesBuilder do
  describe '.call' do
    it 'formats message for tag with specific types forbidden' do
      offense = {
        tag_name: 'return',
        types_text: 'void',
        pattern_types: 'void'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        "Forbidden tag pattern detected: @return [void]. " \
        "Type(s) 'void' are not allowed for @return."
      )
    end

    it 'formats message for tag-only pattern (no types)' do
      offense = {
        tag_name: 'api',
        types_text: '',
        pattern_types: ''
      }

      message = described_class.call(offense)

      expect(message).to eq(
        'Forbidden tag detected: @api. ' \
        'This tag is not allowed by project configuration.'
      )
    end

    it 'formats message with multiple types' do
      offense = {
        tag_name: 'param',
        types_text: 'Object,Hash',
        pattern_types: 'Object,Hash'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        "Forbidden tag pattern detected: @param [Object,Hash]. " \
        "Type(s) 'Object,Hash' are not allowed for @param."
      )
    end

    it 'formats message when types_text is nil' do
      offense = {
        tag_name: 'api',
        types_text: nil,
        pattern_types: nil
      }

      message = described_class.call(offense)

      expect(message).to eq(
        'Forbidden tag detected: @api. ' \
        'This tag is not allowed by project configuration.'
      )
    end
  end
end
