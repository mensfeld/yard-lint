# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::EmptyCommentLine::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Documentation::EmptyCommentLine::Parser.new
  end

  it 'call with leading violations parses single leading violation' do
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

  it 'call with trailing violations parses single trailing violation' do
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

  it 'call with both leading and trailing violations parses multiple violations for same object' do
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

  it 'call with multiple objects parses violations for multiple objects' do
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

  it 'call with multiple leading empty lines parses multiple leading violations' do
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

  it 'call with empty output returns empty array for empty string' do
      result = parser.call('')
      assert_equal([], result)
  end

  it 'call with empty output returns empty array for nil' do
      result = parser.call(nil)
      assert_equal([], result)
  end
end

