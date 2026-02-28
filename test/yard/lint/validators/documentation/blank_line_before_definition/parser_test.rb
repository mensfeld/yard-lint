# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationBlankLineBeforeDefinitionParserTest < Minitest::Test
  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Parser.new
  end

  def test_call_with_single_blank_line_violation_parses_single_blank_line_violation
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        single:1
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 10,
            object_name: 'MyClass#process',
            violation_type: 'single',
            blank_count: 1
          }
        ],
        result
      )
  end

  def test_call_with_orphaned_documentation_violation_parses_orphaned_docs_violation_with_2_blank_lines
      output = <<~OUTPUT
        lib/example.rb:15: MyClass#execute
        orphaned:2
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 15,
            object_name: 'MyClass#execute',
            violation_type: 'orphaned',
            blank_count: 2
          }
        ],
        result
      )
  end

  def test_call_with_orphaned_documentation_violation_parses_orphaned_docs_violation_with_3_blank_lines
      output = <<~OUTPUT
        lib/example.rb:20: MyClass#run
        orphaned:3
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 20,
            object_name: 'MyClass#run',
            violation_type: 'orphaned',
            blank_count: 3
          }
        ],
        result
      )
  end

  def test_call_with_multiple_violations_parses_violations_for_multiple_objects
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        single:1
        lib/example.rb:20: MyClass#execute
        orphaned:2
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 10,
            object_name: 'MyClass#process',
            violation_type: 'single',
            blank_count: 1
          },
          {
            location: 'lib/example.rb',
            line: 20,
            object_name: 'MyClass#execute',
            violation_type: 'orphaned',
            blank_count: 2
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

