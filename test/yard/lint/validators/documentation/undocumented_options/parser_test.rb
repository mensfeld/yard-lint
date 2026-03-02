# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Documentation::UndocumentedOptions::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Documentation::UndocumentedOptions::Parser.new
  end

  it 'call with valid violations parses single violation' do
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

  it 'call with valid violations parses multiple violations' do
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

  it 'call with valid violations parses violation with kwargs' do
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

  it 'call with empty output returns empty array' do
      result = parser.call('')
      assert_equal([], result)
  end
end

