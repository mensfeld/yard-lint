# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TagTypePosition::Parser do
  describe '#call' do
    let(:parser) { described_class.new }

    context 'with valid YARD output' do
      it 'parses violations correctly' do
        output = <<~OUTPUT
          lib/example.rb:25: User#initialize
          param|name|String|type_after_name
          lib/example.rb:35: Order#process
          option|opts|Hash|type_first
        OUTPUT

        result = parser.call(output)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)

        expect(result[0]).to include(
          location: 'lib/example.rb',
          line: 25,
          object_name: 'User#initialize',
          tag_name: 'param',
          param_name: 'name',
          type_info: 'String',
          detected_style: 'type_after_name'
        )

        expect(result[1]).to include(
          location: 'lib/example.rb',
          line: 35,
          object_name: 'Order#process',
          tag_name: 'option',
          param_name: 'opts',
          type_info: 'Hash',
          detected_style: 'type_first'
        )
      end

      it 'handles violations without detected_style' do
        output = <<~OUTPUT
          lib/test.rb:10: Test#method
          param|value|Integer
        OUTPUT

        result = parser.call(output)

        expect(result.size).to eq(1)
        expect(result[0]).to include(
          location: 'lib/test.rb',
          line: 10,
          object_name: 'Test#method',
          tag_name: 'param',
          param_name: 'value',
          type_info: 'Integer',
          detected_style: nil
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
      it 'skips lines without proper location format' do
        output = <<~OUTPUT
          invalid location line
          param|name|String|type_after_name
          lib/example.rb:25: Valid#method
          param|value|Integer|type_first
        OUTPUT

        result = parser.call(output)
        expect(result.size).to eq(1)
        expect(result[0][:object_name]).to eq('Valid#method')
      end

      it 'skips incomplete violation pairs' do
        output = "lib/example.rb:10: Test#method\n"
        result = parser.call(output)
        expect(result).to eq([])
      end

      it 'skips details with insufficient fields' do
        output = <<~OUTPUT
          lib/example.rb:10: Test#method
          param|name
        OUTPUT

        result = parser.call(output)
        expect(result).to eq([])
      end
    end
  end
end
