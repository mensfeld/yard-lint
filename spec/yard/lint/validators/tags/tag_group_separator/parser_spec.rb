# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TagGroupSeparator::Parser do
  let(:parser) { described_class.new }

  describe '#initialize' do
    it 'inherits from parser base class' do
      expect(parser).to be_a(Yard::Lint::Parsers::Base)
    end
  end

  describe '#call' do
    it 'parses input and returns array' do
      result = parser.call('')
      expect(result).to be_an(Array)
    end

    it 'handles empty input' do
      result = parser.call('')
      expect(result).to eq([])
    end

    it 'handles nil input' do
      result = parser.call(nil)
      expect(result).to eq([])
    end

    context 'with valid entries' do
      let(:input) do
        <<~OUTPUT
          lib/example.rb:10: Example#method
          valid
        OUTPUT
      end

      it 'filters out valid entries' do
        result = parser.call(input)
        expect(result).to be_empty
      end
    end

    context 'with offense entries' do
      let(:input) do
        <<~OUTPUT
          lib/example.rb:10: Example#method
          param->return
        OUTPUT
      end

      it 'parses offense entries' do
        result = parser.call(input)
        expect(result.size).to eq(1)
        expect(result.first[:location]).to eq('lib/example.rb')
        expect(result.first[:line]).to eq(10)
        expect(result.first[:method_name]).to eq('method')
        expect(result.first[:separators]).to eq('param->return')
      end
    end

    context 'with multiple offenses' do
      let(:input) do
        <<~OUTPUT
          lib/example.rb:10: Example#method1
          param->return
          lib/example.rb:20: Example#method2
          return->error,error->example
        OUTPUT
      end

      it 'parses all offense entries' do
        result = parser.call(input)
        expect(result.size).to eq(2)
        expect(result[0][:method_name]).to eq('method1')
        expect(result[0][:separators]).to eq('param->return')
        expect(result[1][:method_name]).to eq('method2')
        expect(result[1][:separators]).to eq('return->error,error->example')
      end
    end
  end
end
