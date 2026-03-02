# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Documentation::MarkdownSyntax::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Documentation::MarkdownSyntax::Parser.new
  end

  it 'call with valid violations parses single error' do
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

  it 'call with valid violations parses multiple errors for same object' do
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

  it 'call with valid violations parses multiple violations' do
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

  it 'call with valid violations parses invalid list marker with line number' do
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

  it 'call with empty output returns empty array' do
      result = parser.call('')
      assert_equal([], result)
  end
end

