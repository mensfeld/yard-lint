# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::NonAsciiType::Parser do
  let(:parser) { described_class.new }

  describe '#call' do
    context 'with valid output' do
      let(:output) do
        <<~OUTPUT
          lib/example.rb:10: Example#method
          param|Symbol, …|…|U+2026
          lib/example.rb:20: Example#other_method
          return|String→Integer|→|U+2192
        OUTPUT
      end

      it 'parses violations correctly' do
        result = parser.call(output)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)

        first = result[0]
        expect(first[:location]).to eq('lib/example.rb')
        expect(first[:line]).to eq(10)
        expect(first[:method_name]).to eq('Example#method')
        expect(first[:tag_name]).to eq('param')
        expect(first[:type_string]).to eq('Symbol, …')
        expect(first[:character]).to eq('…')
        expect(first[:codepoint]).to eq('U+2026')

        second = result[1]
        expect(second[:location]).to eq('lib/example.rb')
        expect(second[:line]).to eq(20)
        expect(second[:method_name]).to eq('Example#other_method')
        expect(second[:tag_name]).to eq('return')
        expect(second[:type_string]).to eq('String→Integer')
        expect(second[:character]).to eq('→')
        expect(second[:codepoint]).to eq('U+2192')
      end
    end

    context 'with em dash character' do
      let(:output) do
        <<~OUTPUT
          lib/example.rb:15: Example#method
          param|String—Integer|—|U+2014
        OUTPUT
      end

      it 'parses em dash violations correctly' do
        result = parser.call(output)

        expect(result.size).to eq(1)
        expect(result[0][:character]).to eq('—')
        expect(result[0][:codepoint]).to eq('U+2014')
      end
    end

    context 'with empty output' do
      it 'returns empty array for nil' do
        expect(parser.call(nil)).to eq([])
      end

      it 'returns empty array for empty string' do
        expect(parser.call('')).to eq([])
      end

      it 'returns empty array for whitespace only' do
        expect(parser.call("  \n  \t  ")).to eq([])
      end
    end

    context 'with malformed output' do
      it 'skips lines that do not match expected format' do
        malformed = <<~OUTPUT
          invalid line without colon
          also invalid
          lib/example.rb:10: Example#method
          param|Symbol, …|…|U+2026
        OUTPUT

        result = parser.call(malformed)
        expect(result.size).to eq(1)
        expect(result[0][:location]).to eq('lib/example.rb')
      end

      it 'skips details lines without enough pipe-separated parts' do
        incomplete = <<~OUTPUT
          lib/example.rb:10: Example#method
          param|Symbol, …|…
        OUTPUT

        result = parser.call(incomplete)
        expect(result).to eq([])
      end
    end

    context 'with encoding issues' do
      it 'handles strings with invalid UTF-8 sequences' do
        # Create a string with invalid UTF-8 byte sequence
        invalid_utf8 = +"lib/example.rb:10: Example#method\nparam|test|x|\xFF\xFE"
        invalid_utf8.force_encoding('UTF-8')

        # Should not raise and should return empty (malformed details)
        expect { parser.call(invalid_utf8) }.not_to raise_error
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Parsers::Base' do
      expect(described_class.superclass).to eq(Yard::Lint::Parsers::Base)
    end
  end
end
