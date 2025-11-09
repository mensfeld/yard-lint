# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::MeaninglessTag::Parser do
  let(:parser) { described_class.new }

  describe '#call' do
    context 'with valid YARD output' do
      let(:yard_output) do
        <<~OUTPUT
          lib/example.rb:10: InvalidClass
          class|param
          lib/example.rb:25: InvalidModule
          module|option
        OUTPUT
      end

      it 'parses violations correctly' do
        result = parser.call(yard_output)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)

        first = result[0]
        expect(first[:location]).to eq('lib/example.rb')
        expect(first[:line]).to eq(10)
        expect(first[:object_name]).to eq('InvalidClass')
        expect(first[:object_type]).to eq('class')
        expect(first[:tag_name]).to eq('param')

        second = result[1]
        expect(second[:location]).to eq('lib/example.rb')
        expect(second[:line]).to eq(25)
        expect(second[:object_name]).to eq('InvalidModule')
        expect(second[:object_type]).to eq('module')
        expect(second[:tag_name]).to eq('option')
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
      it 'skips lines without proper format' do
        yard_output = <<~OUTPUT
          malformed line
          another bad line
        OUTPUT

        result = parser.call(yard_output)
        expect(result).to eq([])
      end

      it 'skips incomplete violation pairs' do
        yard_output = <<~OUTPUT
          lib/example.rb:10: InvalidClass
        OUTPUT

        result = parser.call(yard_output)
        expect(result).to eq([])
      end
    end
  end
end
