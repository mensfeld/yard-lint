# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Parser.new
  end

  it 'call with single blank line violation parses single blank line violation' do
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

  it 'call with orphaned documentation violation parses orphaned docs violation with 2 blank lines' do
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

  it 'call with orphaned documentation violation parses orphaned docs violation with 3 blank lines' do
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

  it 'call with multiple violations parses violations for multiple objects' do
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

  it 'call with empty output returns empty array for empty string' do
      result = parser.call('')
      assert_equal([], result)
  end

  it 'call with empty output returns empty array for nil' do
      result = parser.call(nil)
      assert_equal([], result)
  end
end

