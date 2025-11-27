# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::InformalNotation::Parser do
  let(:parser) { described_class.new }

  describe '#call' do
    context 'with valid YARD output' do
      let(:yard_output) do
        <<~OUTPUT
          lib/example.rb:10: MyClass#my_method
          Note|@note|0|Note: This is important
          lib/example.rb:25: AnotherClass
          TODO|@todo|2|TODO: Fix this later
        OUTPUT
      end

      it 'parses violations correctly' do
        result = parser.call(yard_output)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)

        first = result[0]
        expect(first[:location]).to eq('lib/example.rb')
        expect(first[:line]).to eq(10)
        expect(first[:object_name]).to eq('MyClass#my_method')
        expect(first[:pattern]).to eq('Note')
        expect(first[:replacement]).to eq('@note')
        expect(first[:line_offset]).to eq(0)
        expect(first[:line_text]).to eq('Note: This is important')

        second = result[1]
        expect(second[:location]).to eq('lib/example.rb')
        expect(second[:line]).to eq(25)
        expect(second[:object_name]).to eq('AnotherClass')
        expect(second[:pattern]).to eq('TODO')
        expect(second[:replacement]).to eq('@todo')
        expect(second[:line_offset]).to eq(2)
        expect(second[:line_text]).to eq('TODO: Fix this later')
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
          lib/example.rb:10: MyClass#method
        OUTPUT

        result = parser.call(yard_output)
        expect(result).to eq([])
      end
    end

    context 'with missing line_text' do
      it 'handles missing line_text gracefully' do
        yard_output = <<~OUTPUT
          lib/example.rb:10: MyClass#method
          Note|@note|0|
        OUTPUT

        result = parser.call(yard_output)
        expect(result.size).to eq(1)
        expect(result[0][:line_text]).to eq('')
      end
    end
  end
end
