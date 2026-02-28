# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationEmptyCommentLineParserTest < Minitest::Test
  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Documentation::EmptyCommentLine::Parser.new
  end

  def test_call_with_leading_violations_parses_single_leading_violation
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        leading:5
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 5,
            object_line: 10,
            object_name: 'MyClass#process',
            violation_type: 'leading'
          }
        ],
        result
      )
  end

  def test_call_with_trailing_violations_parses_single_trailing_violation
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        trailing:9
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 9,
            object_line: 10,
            object_name: 'MyClass#process',
            violation_type: 'trailing'
          }
        ],
        result
      )
  end

  def test_call_with_both_leading_and_trailing_violations_parses_multiple_violations_for_same_object
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        leading:5|trailing:9
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 5,
            object_line: 10,
            object_name: 'MyClass#process',
            violation_type: 'leading'
          },
          {
            location: 'lib/example.rb',
            line: 9,
            object_line: 10,
            object_name: 'MyClass#process',
            violation_type: 'trailing'
          }
        ],
        result
      )
  end

  def test_call_with_multiple_objects_parses_violations_for_multiple_objects
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        leading:5
        lib/example.rb:20: MyClass#execute
        trailing:19
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 5,
            object_line: 10,
            object_name: 'MyClass#process',
            violation_type: 'leading'
          },
          {
            location: 'lib/example.rb',
            line: 19,
            object_line: 20,
            object_name: 'MyClass#execute',
            violation_type: 'trailing'
          }
        ],
        result
      )
  end

  def test_call_with_multiple_leading_empty_lines_parses_multiple_leading_violations
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        leading:5|leading:6
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 5,
            object_line: 10,
            object_name: 'MyClass#process',
            violation_type: 'leading'
          },
          {
            location: 'lib/example.rb',
            line: 6,
            object_line: 10,
            object_name: 'MyClass#process',
            violation_type: 'leading'
          }
        ],
        result
      )
  end

  def test_call_with_empty_output_returns_empty_array_for_empty_string
      result = parser.call('')
      assert_equal([], result)
  end

  def test_call_with_empty_output_returns_empty_array_for_nil
      result = parser.call(nil)
      assert_equal([], result)
  end
end

