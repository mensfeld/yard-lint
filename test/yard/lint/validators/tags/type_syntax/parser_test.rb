# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::TypeSyntax::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Tags::TypeSyntax::Parser.new
  end

  it 'call with valid yard output parses violations correctly' do
    yard_output = <<~OUTPUT
      lib/example.rb:10: Example#method
      param|Array<|expecting name, got ''
      lib/example.rb:20: Example#other_method
      return|Array<>|expecting name, got '>'
    OUTPUT

    result = parser.call(yard_output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    first = result[0]
    assert_equal('lib/example.rb', first[:location])
    assert_equal(10, first[:line])
    assert_equal('Example#method', first[:method_name])
    assert_equal('param', first[:tag_name])
    assert_equal('Array<', first[:type_string])
    assert_equal("expecting name, got ''", first[:error_message])

    second = result[1]
    assert_equal('lib/example.rb', second[:location])
    assert_equal(20, second[:line])
    assert_equal('Example#other_method', second[:method_name])
    assert_equal('return', second[:tag_name])
    assert_equal('Array<>', second[:type_string])
    assert_equal("expecting name, got '>'", second[:error_message])
  end

  it 'call with empty output returns empty array for nil' do
    assert_equal([], parser.call(nil))
  end

  it 'call with empty output returns empty array for empty string' do
    assert_equal([], parser.call(''))
  end

  it 'call with empty output returns empty array for whitespace only' do
    assert_equal([], parser.call("  \n  \t  "))
  end

  it 'call with malformed output skips lines that do not match expected format' do
    malformed = <<~OUTPUT
      invalid line without colon
      also invalid
      lib/example.rb:10: Example#method
      param|Array<|expecting name, got ''
    OUTPUT

    result = parser.call(malformed)
    assert_equal(1, result.size)
    assert_equal('lib/example.rb', result[0][:location])
  end

  it 'call with malformed output skips details lines without enough pipe separated parts' do
    incomplete = <<~OUTPUT
      lib/example.rb:10: Example#method
      param|Array<
    OUTPUT

    result = parser.call(incomplete)
    assert_equal([], result)
  end

  it 'inheritance inherits from parsers base' do
    assert_equal(Yard::Lint::Parsers::Base, Yard::Lint::Validators::Tags::TypeSyntax::Parser.superclass)
  end
end

