# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsInformalNotationParserTest < Minitest::Test
  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::InformalNotation::Parser.new
  end

  def test_call_with_valid_yard_output_parses_violations_correctly
    yard_output = <<~OUTPUT
      lib/example.rb:10: MyClass#my_method
      Note|@note|0|Note: This is important
      lib/example.rb:25: AnotherClass
      TODO|@todo|2|TODO: Fix this later
    OUTPUT

    result = parser.call(yard_output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    first = result[0]
    assert_equal('lib/example.rb', first[:location])
    assert_equal(10, first[:line])
    assert_equal('MyClass#my_method', first[:object_name])
    assert_equal('Note', first[:pattern])
    assert_equal('@note', first[:replacement])
    assert_equal(0, first[:line_offset])
    assert_equal('Note: This is important', first[:line_text])

    second = result[1]
    assert_equal('lib/example.rb', second[:location])
    assert_equal(25, second[:line])
    assert_equal('AnotherClass', second[:object_name])
    assert_equal('TODO', second[:pattern])
    assert_equal('@todo', second[:replacement])
    assert_equal(2, second[:line_offset])
    assert_equal('TODO: Fix this later', second[:line_text])
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
      lib/example.rb:10: MyClass#method
    OUTPUT

    result = parser.call(yard_output)
    assert_equal([], result)
  end

  def test_call_with_missing_line_text_handles_missing_line_text_gracefully
    yard_output = <<~OUTPUT
      lib/example.rb:10: MyClass#method
      Note|@note|0|
    OUTPUT

    result = parser.call(yard_output)
    assert_equal(1, result.size)
    assert_equal('', result[0][:line_text])
  end
end
