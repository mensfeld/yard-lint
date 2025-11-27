# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::NonAsciiType::MessagesBuilder do
  describe '.call' do
    it 'formats non-ASCII type violation message with ellipsis' do
      offense = {
        tag_name: 'param',
        type_string: 'Symbol, …',
        character: '…',
        codepoint: 'U+2026'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        "Type specification in @param tag contains non-ASCII character '…' (U+2026) " \
        "in 'Symbol, …'. Ruby type names must use ASCII characters only."
      )
    end

    it 'formats non-ASCII type violation message with arrow' do
      offense = {
        tag_name: 'return',
        type_string: 'String→Integer',
        character: '→',
        codepoint: 'U+2192'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        "Type specification in @return tag contains non-ASCII character '→' (U+2192) " \
        "in 'String→Integer'. Ruby type names must use ASCII characters only."
      )
    end

    it 'formats non-ASCII type violation message with em dash' do
      offense = {
        tag_name: 'option',
        type_string: 'String—Integer',
        character: '—',
        codepoint: 'U+2014'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        "Type specification in @option tag contains non-ASCII character '—' (U+2014) " \
        "in 'String—Integer'. Ruby type names must use ASCII characters only."
      )
    end

    it 'handles yieldreturn tag violations' do
      offense = {
        tag_name: 'yieldreturn',
        type_string: 'Résult',
        character: 'é',
        codepoint: 'U+00E9'
      }

      message = described_class.call(offense)

      expect(message).to include('@yieldreturn tag')
      expect(message).to include("'é'")
      expect(message).to include('U+00E9')
    end
  end
end
