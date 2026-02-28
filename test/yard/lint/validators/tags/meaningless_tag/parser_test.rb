# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsMeaninglessTagParserTest < Minitest::Test

  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::MeaninglessTag::Parser.new
  end

  def test_call_with_valid_yard_output_parses_violations_correctly
    yard_output = <<~OUTPUT
      lib/example.rb:10: InvalidClass
      class|param
      lib/example.rb:25: InvalidModule
      module|option
    OUTPUT

    result = parser.call(yard_output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    first = result[0]
    assert_equal('lib/example.rb', first[:location])
    assert_equal(10, first[:line])
    assert_equal('InvalidClass', first[:object_name])
    assert_equal('class', first[:object_type])
    assert_equal('param', first[:tag_name])

    second = result[1]
    assert_equal('lib/example.rb', second[:location])
    assert_equal(25, second[:line])
    assert_equal('InvalidModule', second[:object_name])
    assert_equal('module', second[:object_type])
    assert_equal('option', second[:tag_name])
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

  def test_call_with_malformed_output_skips_lines_without_proper_format
    yard_output = <<~OUTPUT
      malformed line
      another bad line
    OUTPUT

    result = parser.call(yard_output)
    assert_equal([], result)
  end

  def test_call_with_malformed_output_skips_incomplete_violation_pairs
    yard_output = <<~OUTPUT
      lib/example.rb:10: InvalidClass
    OUTPUT

    result = parser.call(yard_output)
    assert_equal([], result)
  end
end
