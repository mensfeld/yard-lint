# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TypeSyntax::Parser do
  let(:parser) { described_class.new }

  describe '#call' do
    context 'with valid YARD output' do
      let(:yard_output) do
        <<~OUTPUT
          lib/example.rb:10: Example#method
          param|Array<|expecting name, got ''
          lib/example.rb:20: Example#other_method
          return|Array<>|expecting name, got '>'
        OUTPUT
      end

      it 'parses violations correctly' do
        result = parser.call(yard_output)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)

        first = result[0]
        expect(first[:location]).to eq('lib/example.rb')
        expect(first[:line]).to eq(10)
        expect(first[:method_name]).to eq('Example#method')
        expect(first[:tag_name]).to eq('param')
        expect(first[:type_string]).to eq('Array<')
        expect(first[:error_message]).to eq("expecting name, got ''")

        second = result[1]
        expect(second[:location]).to eq('lib/example.rb')
        expect(second[:line]).to eq(20)
        expect(second[:method_name]).to eq('Example#other_method')
        expect(second[:tag_name]).to eq('return')
        expect(second[:type_string]).to eq('Array<>')
        expect(second[:error_message]).to eq("expecting name, got '>'")
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
          param|Array<|expecting name, got ''
        OUTPUT

        result = parser.call(malformed)
        expect(result.size).to eq(1)
        expect(result[0][:location]).to eq('lib/example.rb')
      end

      it 'skips details lines without enough pipe-separated parts' do
        incomplete = <<~OUTPUT
          lib/example.rb:10: Example#method
          param|Array<
        OUTPUT

        result = parser.call(incomplete)
        expect(result).to eq([])
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Parsers::Base' do
      expect(described_class.superclass).to eq(Yard::Lint::Parsers::Base)
    end
  end
end
