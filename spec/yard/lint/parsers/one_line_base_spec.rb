# frozen_string_literal: true

RSpec.describe Yard::Lint::Parsers::OneLineBase do
  let(:parser_class) do
    Class.new(described_class) do
      self.regexps = {
        general: /^Error:/,
        message: /Error: (.+) in/,
        location: /in (.+\.rb) at/,
        line: /line (\d+)/
      }.freeze
    end
  end

  let(:parser) { parser_class.new }

  describe '#call' do
    it 'parses matching lines' do
      stdout = "Error: Something wrong in file.rb at line 10\n"
      result = parser.call(stdout)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:location]).to eq('file.rb')
      expect(result.first[:line]).to eq(10)
      expect(result.first[:message]).to eq('Something wrong')
    end

    it 'ignores non-matching lines' do
      stdout = "Random text\nNot matching\n"
      result = parser.call(stdout)

      expect(result).to eq([])
    end

    it 'handles empty input' do
      stdout = ''
      result = parser.call(stdout)
      expect(result).to eq([])
    end

    it 'handles multiple matching lines' do
      stdout = "Error: First in file1.rb at line 5\nError: Second in file2.rb at line 10\n"
      result = parser.call(stdout)

      expect(result.size).to eq(2)
    end
  end

  describe 'inheritance' do
    it 'can be subclassed' do
      expect(parser).to be_a(described_class)
    end
  end
end
