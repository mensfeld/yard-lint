# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationMarkdownSyntaxParserTest < Minitest::Test
  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Documentation::MarkdownSyntax::Parser.new
  end

  def test_call_with_valid_violations_parses_single_error
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        unclosed_backtick
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 10,
            object_name: 'MyClass#process',
            errors: %w[unclosed_backtick]
          }
        ],
        result
      )
  end

  def test_call_with_valid_violations_parses_multiple_errors_for_same_object
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        unclosed_backtick|unclosed_bold
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 10,
            object_name: 'MyClass#process',
            errors: %w[unclosed_backtick unclosed_bold]
          }
        ],
        result
      )
  end

  def test_call_with_valid_violations_parses_multiple_violations
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        unclosed_backtick
        lib/example.rb:20: MyClass#execute
        unclosed_bold
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 10,
            object_name: 'MyClass#process',
            errors: %w[unclosed_backtick]
          },
          {
            location: 'lib/example.rb',
            line: 20,
            object_name: 'MyClass#execute',
            errors: %w[unclosed_bold]
          }
        ],
        result
      )
  end

  def test_call_with_valid_violations_parses_invalid_list_marker_with_line_number
      output = <<~OUTPUT
        lib/example.rb:15: MyClass#configure
        invalid_list_marker:3
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 15,
            object_name: 'MyClass#configure',
            errors: %w[invalid_list_marker:3]
          }
        ],
        result
      )
  end

  def test_call_with_empty_output_returns_empty_array
      result = parser.call('')
      assert_equal([], result)
  end
end

