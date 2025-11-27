# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder do
  describe '.call' do
    it 'formats message for Note pattern' do
      offense = {
        pattern: 'Note',
        replacement: '@note',
        line_text: 'Note: This is important'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        "Use @note tag instead of 'Note:' notation. Found: \"Note: This is important\""
      )
    end

    it 'formats message for TODO pattern' do
      offense = {
        pattern: 'TODO',
        replacement: '@todo',
        line_text: 'TODO: Fix this later'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        "Use @todo tag instead of 'TODO:' notation. Found: \"TODO: Fix this later\""
      )
    end

    it 'formats message for Deprecated pattern' do
      offense = {
        pattern: 'Deprecated',
        replacement: '@deprecated',
        line_text: 'Deprecated: Use new_method instead'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        "Use @deprecated tag instead of 'Deprecated:' notation. " \
        'Found: "Deprecated: Use new_method instead"'
      )
    end

    it 'handles empty line_text' do
      offense = {
        pattern: 'Note',
        replacement: '@note',
        line_text: ''
      }

      message = described_class.call(offense)

      expect(message).to eq("Use @note tag instead of 'Note:' notation")
    end

    it 'handles nil line_text' do
      offense = {
        pattern: 'Note',
        replacement: '@note',
        line_text: nil
      }

      message = described_class.call(offense)

      expect(message).to eq("Use @note tag instead of 'Note:' notation")
    end

    it 'truncates long line_text' do
      long_text = 'Note: ' + ('x' * 100)
      offense = {
        pattern: 'Note',
        replacement: '@note',
        line_text: long_text
      }

      message = described_class.call(offense)

      expect(message).to include('...')
      expect(message.length).to be < (long_text.length + 50)
    end
  end
end
