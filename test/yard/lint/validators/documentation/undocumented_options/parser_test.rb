# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationUndocumentedOptionsParserTest < Minitest::Test
  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Documentation::UndocumentedOptions::Parser.new
  end

  def test_call_with_valid_violations_parses_single_violation
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        data, options = {}
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 10,
            object_name: 'MyClass#process',
            params: 'data, options = {}'
          }
        ],
        result
      )
  end

  def test_call_with_valid_violations_parses_multiple_violations
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#process
        data, options = {}
        lib/example.rb:20: MyClass#execute
        data, opts = {}
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 10,
            object_name: 'MyClass#process',
            params: 'data, options = {}'
          },
          {
            location: 'lib/example.rb',
            line: 20,
            object_name: 'MyClass#execute',
            params: 'data, opts = {}'
          }
        ],
        result
      )
  end

  def test_call_with_valid_violations_parses_violation_with_kwargs
      output = <<~OUTPUT
        lib/example.rb:15: MyClass#configure
        **options
      OUTPUT

      result = parser.call(output)

      assert_equal(
        [
          {
            location: 'lib/example.rb',
            line: 15,
            object_name: 'MyClass#configure',
            params: '**options'
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

