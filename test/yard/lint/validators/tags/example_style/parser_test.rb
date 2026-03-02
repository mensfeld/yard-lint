# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::ExampleStyle::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Tags::ExampleStyle::Parser.new
  end

  it 'initialize inherits from parser base class' do
    assert_kind_of(Yard::Lint::Parsers::Base, parser)
  end

  it 'call parses input and returns array' do
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  it 'call handles empty input' do
    result = parser.call('')
    assert_equal([], result)
  end

  it 'call parses style offense output correctly' do
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      style_offense
      Basic usage
      Style/StringLiterals
      Prefer single-quoted strings when you don't need interpolation
    OUTPUT

    result = parser.call(output)
    assert_equal(
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
      ],
      result
    )
  end

  it 'call parses multiple offenses correctly' do
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
    assert_equal(2, result.length)
    assert_equal('Style/StringLiterals', result[0][:cop_name])
    assert_equal('Layout/SpaceInsideParens', result[1][:cop_name])
  end

  it 'call handles nil input' do
    result = parser.call(nil)
    assert_equal([], result)
  end

  it 'call ignores lines that do not match location pattern' do
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
    assert_equal(1, result.length)
    assert_equal('Example#method', result[0][:object_name])
  end

  it 'call skips non style offense entries' do
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      other_offense
      Basic usage
      Style/StringLiterals
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal([], result)
  end

  it 'call handles file paths starting with dot' do
    output = <<~OUTPUT
      ./lib/example.rb:10: Example#method
      style_offense
      Basic usage
      Style/StringLiterals
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('./lib/example.rb', result[0][:location])
  end

  it 'call handles file paths starting with slash' do
    output = <<~OUTPUT
      /home/user/lib/example.rb:10: Example#method
      style_offense
      Basic usage
      Style/StringLiterals
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('/home/user/lib/example.rb', result[0][:location])
  end

  it 'call handles incomplete output gracefully' do
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      style_offense
      Basic usage
    OUTPUT

    result = parser.call(output)
    assert_equal([], result)
  end
end

