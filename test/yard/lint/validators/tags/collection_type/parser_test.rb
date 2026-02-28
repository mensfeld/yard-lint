# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsCollectionTypeParserTest < Minitest::Test

  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::CollectionType::Parser.new
  end

  def test_call_with_valid_yard_output_parses_violations_correctly_with_short_style_detected
    output = <<~OUTPUT
      spec/fixtures/collection_type_examples.rb:25: InvalidHashSyntax#process
      param|Hash<Symbol, String>|short
      spec/fixtures/collection_type_examples.rb:35: InvalidNestedHash#process
      param|Hash<String, Hash<Symbol, Integer>>|short
    OUTPUT

    result = parser.call(output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    assert_equal('spec/fixtures/collection_type_examples.rb', result[0][:location])
    assert_equal(25, result[0][:line])
    assert_equal('InvalidHashSyntax#process', result[0][:object_name])
    assert_equal('param', result[0][:tag_name])
    assert_equal('Hash<Symbol, String>', result[0][:type_string])
    assert_equal('short', result[0][:detected_style])

    assert_equal('spec/fixtures/collection_type_examples.rb', result[1][:location])
    assert_equal(35, result[1][:line])
    assert_equal('InvalidNestedHash#process', result[1][:object_name])
    assert_equal('param', result[1][:tag_name])
    assert_equal('Hash<String, Hash<Symbol, Integer>>', result[1][:type_string])
    assert_equal('short', result[1][:detected_style])
  end

  def test_call_with_valid_yard_output_parses_violations_correctly_with_long_style_detected
    output = <<~OUTPUT
      spec/fixtures/collection_type_examples.rb:42: ValidHashSyntax#process
      param|Hash{Symbol => String}|long
    OUTPUT

    result = parser.call(output)

    assert_kind_of(Array, result)
    assert_equal(1, result.size)

    assert_equal('spec/fixtures/collection_type_examples.rb', result[0][:location])
    assert_equal(42, result[0][:line])
    assert_equal('ValidHashSyntax#process', result[0][:object_name])
    assert_equal('param', result[0][:tag_name])
    assert_equal('Hash{Symbol => String}', result[0][:type_string])
    assert_equal('long', result[0][:detected_style])
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
    output = <<~OUTPUT
      spec/fixtures/test.rb:10: Test#method
      param|Hash<K, V>|short
      invalid line without pipe
      another invalid line
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.size)
  end

  def test_call_with_malformed_output_skips_incomplete_violation_pairs
    output = "spec/fixtures/test.rb:10: Test#method\n"
    result = parser.call(output)
    assert_equal([], result)
  end
end
