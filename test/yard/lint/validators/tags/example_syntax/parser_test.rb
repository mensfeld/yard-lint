# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsExampleSyntaxParserTest < Minitest::Test

  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::ExampleSyntax::Parser.new
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

  def test_call_parses_syntax_error_output_correctly
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      syntax_error
      Basic usage
      syntax error, unexpected end-of-input
    OUTPUT

    result = parser.call(output)
    assert_equal(
      [
        {
          name: 'ExampleSyntax',
          object_name: 'Example#method',
          example_name: 'Basic usage',
          error_message: 'syntax error, unexpected end-of-input',
          location: 'lib/example.rb',
          line: 10
        }
      ],
      result
    )
  end

  def test_call_parses_multi_line_syntax_error_output_correctly
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      syntax_error
      Basic usage
      <compiled>:1: syntax errors found
      > 1 | result = broken
          |                ^ unexpected end-of-input
    OUTPUT

    result = parser.call(output)
    assert_equal(
      [
        {
          name: 'ExampleSyntax',
          object_name: 'Example#method',
          example_name: 'Basic usage',
          error_message: "<compiled>:1: syntax errors found\n> 1 | result = broken\n    " \
                         '|                ^ unexpected end-of-input',
          location: 'lib/example.rb',
          line: 10
        }
      ],
      result
    )
  end

  def test_call_parses_multiple_errors_correctly
    output = <<~OUTPUT
      lib/example.rb:10: Example#method1
      syntax_error
      First example
      error line 1
      error line 2
      lib/example.rb:20: Example#method2
      syntax_error
      Second example
      another error
    OUTPUT

    result = parser.call(output)
    assert_equal(2, result.length)
    assert_equal("error line 1\nerror line 2", result[0][:error_message])
    assert_equal('another error', result[1][:error_message])
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
      syntax_error
      Basic usage
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('Example#method', result[0][:object_name])
  end

  def test_call_skips_errors_without_syntax_error_status
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      other_error
      Basic usage
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal([], result)
  end

  def test_call_handles_file_paths_starting_with_dot
    output = <<~OUTPUT
      ./lib/example.rb:10: Example#method
      syntax_error
      Basic usage
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('./lib/example.rb', result[0][:location])
  end

  def test_call_handles_file_paths_starting_with_slash
    output = <<~OUTPUT
      /home/user/lib/example.rb:10: Example#method
      syntax_error
      Basic usage
      error message
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('/home/user/lib/example.rb', result[0][:location])
  end

  def test_call_does_not_match_compiled_as_file_path
    output = <<~OUTPUT
      lib/example.rb:10: Example#method
      syntax_error
      Basic usage
      <compiled>:1: syntax error
      more error details
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_includes(result[0][:error_message], '<compiled>:1: syntax error')
  end
end
