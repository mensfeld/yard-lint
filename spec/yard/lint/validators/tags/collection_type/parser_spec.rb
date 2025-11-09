# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::CollectionType::Parser do
  describe '#call' do
    let(:parser) { described_class.new }

    context 'with valid YARD output' do
      it 'parses violations correctly' do
        output = <<~OUTPUT
          spec/fixtures/collection_type_examples.rb:25: InvalidHashSyntax#process
          param|Hash<Symbol, String>
          spec/fixtures/collection_type_examples.rb:35: InvalidNestedHash#process
          param|Hash<String, Hash<Symbol, Integer>>
        OUTPUT

        result = parser.call(output)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)

        expect(result[0]).to include(
          location: 'spec/fixtures/collection_type_examples.rb',
          line: 25,
          object_name: 'InvalidHashSyntax#process',
          tag_name: 'param',
          type_string: 'Hash<Symbol, String>'
        )

        expect(result[1]).to include(
          location: 'spec/fixtures/collection_type_examples.rb',
          line: 35,
          object_name: 'InvalidNestedHash#process',
          tag_name: 'param',
          type_string: 'Hash<String, Hash<Symbol, Integer>>'
        )
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
        output = <<~OUTPUT
          spec/fixtures/test.rb:10: Test#method
          param|Hash<K, V>
          invalid line without pipe
          another invalid line
        OUTPUT

        result = parser.call(output)
        expect(result.size).to eq(1)
      end

      it 'skips incomplete violation pairs' do
        output = "spec/fixtures/test.rb:10: Test#method\n"
        result = parser.call(output)
        expect(result).to eq([])
      end
    end
  end
end
