# frozen_string_literal: true

RSpec.describe Yard::Lint::Parsers::TwoLineBase do
  let(:parser_class) do
    Class.new(described_class) do
      self.regexps = {
        general: /^Error:/,
        message: /^Error: (.+)$/,
        location: /^  in (.+\.rb) at line/,
        line: /^  in .+ at line (\d+)$/
      }.freeze
    end
  end

  let(:parser) { parser_class.new }

  describe '#call' do
    it 'parses two-line patterns' do
      input = "Error: Something wrong\n  in file.rb at line 10\n"
      result = parser.call(input)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:location]).to eq('file.rb')
      expect(result.first[:line]).to eq(10)
      expect(result.first[:message]).to eq('Something wrong')
    end

    it 'ignores incomplete patterns' do
      input = "Error: Something\nNot matching second line\n"
      result = parser.call(input)

      expect(result.size).to eq(1)
      expect(result.first[:location]).to be_nil
      expect(result.first[:line]).to eq(0)
    end

    it 'handles empty input' do
      result = parser.call('')
      expect(result).to eq([])
    end

    it 'handles multiple two-line patterns' do
      input = "Error: First\n  in file1.rb at line 5\nError: Second\n  in file2.rb at line 10\n"
      result = parser.call(input)

      expect(result.size).to eq(2)
    end
  end

  describe 'inheritance' do
    it 'can be subclassed' do
      expect(parser).to be_a(described_class)
    end
  end
end
