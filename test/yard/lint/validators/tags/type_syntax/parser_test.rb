# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTypeSyntaxParserTest < Minitest::Test

  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::TypeSyntax::Parser.new
  end

  def test_call_with_valid_yard_output_parses_violations_correctly
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

  def test_call_with_empty_output_returns_empty_array_for_nil
    assert_equal([], parser.call(nil))
  end

  def test_call_with_empty_output_returns_empty_array_for_empty_string
    assert_equal([], parser.call(''))
  end

  def test_call_with_empty_output_returns_empty_array_for_whitespace_only
    assert_equal([], parser.call("  \n  \t  "))
  end

  def test_call_with_malformed_output_skips_lines_that_do_not_match_expected_format
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

  def test_call_with_malformed_output_skips_details_lines_without_enough_pipe_separated_parts
    incomplete = <<~OUTPUT
      lib/example.rb:10: Example#method
      param|Array<
    OUTPUT

    result = parser.call(incomplete)
    assert_equal([], result)
  end

  def test_inheritance_inherits_from_parsers_base
    assert_equal(Yard::Lint::Parsers::Base, Yard::Lint::Validators::Tags::TypeSyntax::Parser.superclass)
  end
end
