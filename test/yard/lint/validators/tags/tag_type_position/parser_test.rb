# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTagTypePositionParserTest < Minitest::Test

  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::TagTypePosition::Parser.new
  end

  def test_call_with_valid_yard_output_parses_violations_correctly
    output = <<~OUTPUT
      lib/example.rb:25: User#initialize
      param|name|String|type_after_name
      lib/example.rb:35: Order#process
      option|opts|Hash|type_first
    OUTPUT

    result = parser.call(output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    assert_equal('lib/example.rb', result[0][:location])
    assert_equal(25, result[0][:line])
    assert_equal('User#initialize', result[0][:object_name])
    assert_equal('param', result[0][:tag_name])
    assert_equal('name', result[0][:param_name])
    assert_equal('String', result[0][:type_info])
    assert_equal('type_after_name', result[0][:detected_style])

    assert_equal('lib/example.rb', result[1][:location])
    assert_equal(35, result[1][:line])
    assert_equal('Order#process', result[1][:object_name])
    assert_equal('option', result[1][:tag_name])
    assert_equal('opts', result[1][:param_name])
    assert_equal('Hash', result[1][:type_info])
    assert_equal('type_first', result[1][:detected_style])
  end

  def test_call_with_valid_yard_output_handles_violations_without_detected_style
    output = <<~OUTPUT
      lib/test.rb:10: Test#method
      param|value|Integer
    OUTPUT

    result = parser.call(output)

    assert_equal(1, result.size)
    assert_equal('lib/test.rb', result[0][:location])
    assert_equal(10, result[0][:line])
    assert_equal('Test#method', result[0][:object_name])
    assert_equal('param', result[0][:tag_name])
    assert_equal('value', result[0][:param_name])
    assert_equal('Integer', result[0][:type_info])
    assert_nil(result[0][:detected_style])
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

  def test_call_with_malformed_output_skips_lines_without_proper_location_format
    output = <<~OUTPUT
      invalid location line
      param|name|String|type_after_name
      lib/example.rb:25: Valid#method
      param|value|Integer|type_first
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.size)
    assert_equal('Valid#method', result[0][:object_name])
  end

  def test_call_with_malformed_output_skips_incomplete_violation_pairs
    output = "lib/example.rb:10: Test#method\n"
    result = parser.call(output)
    assert_equal([], result)
  end

  def test_call_with_malformed_output_skips_details_with_insufficient_fields
    output = <<~OUTPUT
      lib/example.rb:10: Test#method
      param|name
    OUTPUT

    result = parser.call(output)
    assert_equal([], result)
  end
end
