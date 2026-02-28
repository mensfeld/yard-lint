# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsExampleStyleParserTest < Minitest::Test

  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::ExampleStyle::Parser.new
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

  def test_call_parses_style_offense_output_correctly
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      style_offense
      Basic usage
      Style/StringLiterals
      Prefer single-quoted strings when you don't need interpolation
    OUTPUT

    result = parser.call(output)
    assert_equal(
      [
        {
          name: 'ExampleStyle',
          object_name: 'Example#method',
          example_name: 'Basic usage',
          cop_name: 'Style/StringLiterals',
          message: "Prefer single-quoted strings when you don't need interpolation",
          location: 'lib/example.rb',
          line: 10
        }
      ],
      result
    )
  end

  def test_call_parses_multiple_offenses_correctly
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      style_offense
      First example
      Style/StringLiterals
      Prefer single-quoted strings
      lib/example.rb:20: Example#method2
      style_offense
      Second example
      Layout/SpaceInsideParens
      Space inside parentheses detected
    OUTPUT

    result = parser.call(output)
    assert_equal(2, result.length)
    assert_equal('Style/StringLiterals', result[0][:cop_name])
    assert_equal('Layout/SpaceInsideParens', result[1][:cop_name])
  end

  def test_call_handles_nil_input
    result = parser.call(nil)
    assert_equal([], result)
  end

  def test_call_ignores_lines_that_do_not_match_location_pattern
    output = <<~OUTPUT
      random text
      more random text
      lib/example.rb:10: Example#method
      style_offense
      Basic usage
      Style/StringLiterals
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('Example#method', result[0][:object_name])
  end

  def test_call_skips_non_style_offense_entries
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      other_offense
      Basic usage
      Style/StringLiterals
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal([], result)
  end

  def test_call_handles_file_paths_starting_with_dot
    output = <<~OUTPUT
      ./lib/example.rb:10: Example#method
      style_offense
      Basic usage
      Style/StringLiterals
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('./lib/example.rb', result[0][:location])
  end

  def test_call_handles_file_paths_starting_with_slash
    output = <<~OUTPUT
      /home/user/lib/example.rb:10: Example#method
      style_offense
      Basic usage
      Style/StringLiterals
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('/home/user/lib/example.rb', result[0][:location])
  end

  def test_call_handles_incomplete_output_gracefully
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      style_offense
      Basic usage
    OUTPUT

    result = parser.call(output)
    assert_equal([], result)
  end
end
