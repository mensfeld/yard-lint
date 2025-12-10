# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ForbiddenTags::Parser do
  let(:parser) { described_class.new }

  describe '#call' do
    context 'with valid YARD output' do
      let(:yard_output) do
        <<~OUTPUT
          lib/example.rb:10: void_return
          return|void|void
          lib/example.rb:25: object_param
          param|Object|Object
        OUTPUT
      end

      it 'parses violations correctly' do
        result = parser.call(yard_output)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)

        first = result[0]
        expect(first[:location]).to eq('lib/example.rb')
        expect(first[:line]).to eq(10)
        expect(first[:object_name]).to eq('void_return')
        expect(first[:tag_name]).to eq('return')
        expect(first[:types_text]).to eq('void')
        expect(first[:pattern_types]).to eq('void')

        second = result[1]
        expect(second[:location]).to eq('lib/example.rb')
        expect(second[:line]).to eq(25)
        expect(second[:object_name]).to eq('object_param')
        expect(second[:tag_name]).to eq('param')
        expect(second[:types_text]).to eq('Object')
        expect(second[:pattern_types]).to eq('Object')
      end
    end

    context 'with tag-only pattern (no types)' do
      let(:yard_output) do
        <<~OUTPUT
          lib/example.rb:15: ApiClass
          api||
        OUTPUT
      end

      it 'parses violations with empty types' do
        result = parser.call(yard_output)

        expect(result.size).to eq(1)
        expect(result[0][:tag_name]).to eq('api')
        expect(result[0][:types_text]).to eq('')
        expect(result[0][:pattern_types]).to eq('')
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
          lib/example.rb:10: void_return
        OUTPUT

        result = parser.call(yard_output)
        expect(result).to eq([])
      end
    end
  end
end
