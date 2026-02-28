# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTagGroupSeparatorParserTest < Minitest::Test

  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::TagGroupSeparator::Parser.new
  end

  def test_initialize_inherits_from_parser_base_class
    assert_kind_of(Yard::Lint::Parsers::Base, parser)
  end

  def test_call_parses_input_and_returns_array
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  def test_call_handles_empty_input
    result = parser.call('')
    assert_equal([], result)
  end

  def test_call_handles_nil_input
    result = parser.call(nil)
    assert_equal([], result)
  end

  def test_call_with_valid_entries_filters_out_valid_entries
    input = <<~OUTPUT
      lib/example.rb:10: Example#method
      valid
    OUTPUT

    result = parser.call(input)
    assert_empty(result)
  end

  def test_call_with_offense_entries_parses_offense_entries
    input = <<~OUTPUT
      lib/example.rb:10: Example#method
      param->return
    OUTPUT

    result = parser.call(input)
    assert_equal(1, result.size)
    assert_equal('lib/example.rb', result.first[:location])
    assert_equal(10, result.first[:line])
    assert_equal('method', result.first[:method_name])
    assert_equal('param->return', result.first[:separators])
  end

  def test_call_with_multiple_offenses_parses_all_offense_entries
    input = <<~OUTPUT
      lib/example.rb:10: Example#method1
      param->return
      lib/example.rb:20: Example#method2
      return->error,error->example
    OUTPUT

    result = parser.call(input)
    assert_equal(2, result.size)
    assert_equal('method1', result[0][:method_name])
    assert_equal('param->return', result[0][:separators])
    assert_equal('method2', result[1][:method_name])
    assert_equal('return->error,error->example', result[1][:separators])
  end
end
