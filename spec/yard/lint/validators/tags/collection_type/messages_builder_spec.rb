# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder do
  describe '.call' do
    it 'formats message for simple Hash<K, V>' do
      offense = {
        tag_name: 'param',
        type_string: 'Hash<Symbol, String>'
      }

      message = described_class.call(offense)

      expect(message).to include('Hash{Symbol => String}')
      expect(message).to include('instead of Hash<Symbol, String>')
      expect(message).to include('@param')
      expect(message).to include('YARD uses Hash{K => V} syntax')
    end

    it 'formats message for nested Hash' do
      offense = {
        tag_name: 'return',
        type_string: 'Hash<String, Hash<Symbol, Integer>>'
      }

      message = described_class.call(offense)

      expect(message).to include('Hash{String => Hash<Symbol')
      expect(message).to include('@return')
    end

    it 'formats message for @option tag' do
      offense = {
        tag_name: 'option',
        type_string: 'Hash<String, Object>'
      }

      message = described_class.call(offense)

      expect(message).to include('@option')
      expect(message).to include('Hash{String => Object}')
    end
  end
end
