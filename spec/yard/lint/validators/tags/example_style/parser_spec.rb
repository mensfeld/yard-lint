# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ExampleStyle::Parser do
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

    it 'parses style offense output correctly' do
      output = <<~OUTPUT
        lib/example.rb:10: Example#method
        style_offense
        Basic usage
        Style/StringLiterals
        Prefer single-quoted strings when you don't need interpolation
      OUTPUT

      result = parser.call(output)
      expect(result).to eq(
        [
          {
            name: 'ExampleStyle',
            object_name: 'Example#method',
            example_name: 'Basic usage',
            cop_name: 'Style/StringLiterals',
            message: "Prefer single-quoted strings when you don't need interpolation",
            location: 'lib/example.rb',
            line: 10
          }
        ]
      )
    end

    it 'parses multiple offenses correctly' do
      output = <<~OUTPUT
        lib/example.rb:10: Example#method
        style_offense
        First example
        Style/StringLiterals
        Prefer single-quoted strings
        lib/example.rb:20: Example#method2
        style_offense
        Second example
        Layout/SpaceInsideParens
        Space inside parentheses detected
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(2)
      expect(result[0][:cop_name]).to eq('Style/StringLiterals')
      expect(result[1][:cop_name]).to eq('Layout/SpaceInsideParens')
    end

    it 'handles nil input' do
      result = parser.call(nil)
      expect(result).to eq([])
    end

    it 'ignores lines that do not match location pattern' do
      output = <<~OUTPUT
        random text
        more random text
        lib/example.rb:10: Example#method
        style_offense
        Basic usage
        Style/StringLiterals
        error message
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:object_name]).to eq('Example#method')
    end

    it 'skips non-style_offense entries' do
      output = <<~OUTPUT
        lib/example.rb:10: Example#method
        other_offense
        Basic usage
        Style/StringLiterals
        error message
      OUTPUT

      result = parser.call(output)
      expect(result).to eq([])
    end

    it 'handles file paths starting with dot' do
      output = <<~OUTPUT
        ./lib/example.rb:10: Example#method
        style_offense
        Basic usage
        Style/StringLiterals
        error message
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:location]).to eq('./lib/example.rb')
    end

    it 'handles file paths starting with slash' do
      output = <<~OUTPUT
        /home/user/lib/example.rb:10: Example#method
        style_offense
        Basic usage
        Style/StringLiterals
        error message
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:location]).to eq('/home/user/lib/example.rb')
    end

    it 'handles incomplete output gracefully' do
      output = <<~OUTPUT
        lib/example.rb:10: Example#method
        style_offense
        Basic usage
      OUTPUT

      result = parser.call(output)
      expect(result).to eq([])
    end
  end
end
