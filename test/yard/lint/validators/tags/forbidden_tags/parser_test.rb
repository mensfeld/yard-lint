# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsForbiddenTagsParserTest < Minitest::Test

  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::ForbiddenTags::Parser.new
  end

  def test_call_with_valid_yard_output_parses_violations_correctly
    yard_output = <<~OUTPUT
      lib/example.rb:10: void_return
      return|void|void
      lib/example.rb:25: object_param
      param|Object|Object
    OUTPUT

    result = parser.call(yard_output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    first = result[0]
    assert_equal('lib/example.rb', first[:location])
    assert_equal(10, first[:line])
    assert_equal('void_return', first[:object_name])
    assert_equal('return', first[:tag_name])
    assert_equal('void', first[:types_text])
    assert_equal('void', first[:pattern_types])

    second = result[1]
    assert_equal('lib/example.rb', second[:location])
    assert_equal(25, second[:line])
    assert_equal('object_param', second[:object_name])
    assert_equal('param', second[:tag_name])
    assert_equal('Object', second[:types_text])
    assert_equal('Object', second[:pattern_types])
  end

  def test_call_with_tag_only_pattern_no_types_parses_violations_with_empty_types
    yard_output = <<~OUTPUT
      lib/example.rb:15: ApiClass
      api||
    OUTPUT

    result = parser.call(yard_output)

    assert_equal(1, result.size)
    assert_equal('api', result[0][:tag_name])
    assert_equal('', result[0][:types_text])
    assert_equal('', result[0][:pattern_types])
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
      lib/example.rb:10: void_return
    OUTPUT

    result = parser.call(yard_output)
    assert_equal([], result)
  end
end
