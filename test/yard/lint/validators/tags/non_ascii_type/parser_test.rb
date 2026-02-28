# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsNonAsciiTypeParserTest < Minitest::Test

  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::NonAsciiType::Parser.new
  end

  def test_call_with_valid_output_parses_violations_correctly
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

  def test_call_with_em_dash_character_parses_em_dash_violations_correctly
    output = <<~OUTPUT
      lib/example.rb:15: Example#method
      param|String—Integer|—|U+2014
    OUTPUT

    result = parser.call(output)

    assert_equal(1, result.size)
    assert_equal('—', result[0][:character])
    assert_equal('U+2014', result[0][:codepoint])
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
      param|Symbol, …|…|U+2026
    OUTPUT

    result = parser.call(malformed)
    assert_equal(1, result.size)
    assert_equal('lib/example.rb', result[0][:location])
  end

  def test_call_with_malformed_output_skips_details_lines_without_enough_pipe_separated_parts
    incomplete = <<~OUTPUT
      lib/example.rb:10: Example#method
      param|Symbol, …|…
    OUTPUT

    result = parser.call(incomplete)
    assert_equal([], result)
  end

  def test_call_with_encoding_issues_handles_strings_with_invalid_utf_8_sequences
    # Create a string with invalid UTF-8 byte sequence
    invalid_utf8 = +"lib/example.rb:10: Example#method\nparam|test|x|\xFF\xFE"
    invalid_utf8.force_encoding('UTF-8')

    # Should not raise and should return empty (malformed details)
    parser.call(invalid_utf8)
  end

  def test_inheritance_inherits_from_parsers_base
    assert_equal(Yard::Lint::Parsers::Base, Yard::Lint::Validators::Tags::NonAsciiType::Parser.superclass)
  end
end
