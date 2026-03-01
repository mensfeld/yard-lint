# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::NonAsciiType::Parser' do
  attr_reader :parser


  before do
    @parser = Yard::Lint::Validators::Tags::NonAsciiType::Parser.new
  end

  it 'call with valid output parses violations correctly' do
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      param|Symbol, …|…|U+2026
      lib/example.rb:20: Example#other_method
      return|String→Integer|→|U+2192
    OUTPUT

    result = parser.call(output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    first = result[0]
    assert_equal('lib/example.rb', first[:location])
    assert_equal(10, first[:line])
    assert_equal('Example#method', first[:method_name])
    assert_equal('param', first[:tag_name])
    assert_equal('Symbol, …', first[:type_string])
    assert_equal('…', first[:character])
    assert_equal('U+2026', first[:codepoint])

    second = result[1]
    assert_equal('lib/example.rb', second[:location])
    assert_equal(20, second[:line])
    assert_equal('Example#other_method', second[:method_name])
    assert_equal('return', second[:tag_name])
    assert_equal('String→Integer', second[:type_string])
    assert_equal('→', second[:character])
    assert_equal('U+2192', second[:codepoint])
  end

  it 'call with em dash character parses em dash violations correctly' do
    output = <<~OUTPUT
      lib/example.rb:15: Example#method
      param|String—Integer|—|U+2014
    OUTPUT

    result = parser.call(output)

    assert_equal(1, result.size)
    assert_equal('—', result[0][:character])
    assert_equal('U+2014', result[0][:codepoint])
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
      param|Symbol, …|…|U+2026
    OUTPUT

    result = parser.call(malformed)
    assert_equal(1, result.size)
    assert_equal('lib/example.rb', result[0][:location])
  end

  it 'call with malformed output skips details lines without enough pipe separated parts' do
    incomplete = <<~OUTPUT
      lib/example.rb:10: Example#method
      param|Symbol, …|…
    OUTPUT

    result = parser.call(incomplete)
    assert_equal([], result)
  end

  it 'call with encoding issues handles strings with invalid utf 8 sequences' do
    # Create a string with invalid UTF-8 byte sequence
    invalid_utf8 = +"lib/example.rb:10: Example#method\nparam|test|x|\xFF\xFE"
    invalid_utf8.force_encoding('UTF-8')

    # Should not raise and should return empty (malformed details)
    parser.call(invalid_utf8)
  end

  it 'inheritance inherits from parsers base' do
    assert_equal(Yard::Lint::Parsers::Base, Yard::Lint::Validators::Tags::NonAsciiType::Parser.superclass)
  end
end
