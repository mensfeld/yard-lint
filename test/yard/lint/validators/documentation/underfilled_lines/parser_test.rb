# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UnderfilledLines::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Documentation::UnderfilledLines::Parser.new
  end

  it 'call with single violation parses one underfilled paragraph' do
    output = <<~OUTPUT
      lib/example.rb:10: MyClass#process
      120|5:2:1:57
    OUTPUT

    result = parser.call(output)

    assert_equal(
      [
        {
          location: 'lib/example.rb',
          line: 5,
          object_line: 10,
          object_name: 'MyClass#process',
          actual_lines: 2,
          reflowed_lines: 1,
          widest_fill: 57,
          max_length: 120
        }
      ],
      result
    )
  end

  it 'call with multiple paragraphs on same object parses all of them' do
    output = <<~OUTPUT
      lib/example.rb:15: MyClass#execute
      120|3:2:1:55|9:3:2:60
    OUTPUT

    result = parser.call(output)

    assert_equal(2, result.size)
    assert_equal(3, result[0][:line])
    assert_equal(2, result[0][:actual_lines])
    assert_equal(1, result[0][:reflowed_lines])
    assert_equal(55, result[0][:widest_fill])
    assert_equal(9, result[1][:line])
    assert_equal(3, result[1][:actual_lines])
    assert_equal(2, result[1][:reflowed_lines])
    assert_equal(60, result[1][:widest_fill])
  end

  it 'call with multiple objects parses violations from both objects' do
    output = <<~OUTPUT
      lib/a.rb:10: Foo#bar
      120|2:2:1:48
      lib/b.rb:20: Baz#qux
      80|18:2:1:40
    OUTPUT

    result = parser.call(output)

    assert_equal(2, result.size)
    assert_equal('lib/a.rb', result[0][:location])
    assert_equal(120, result[0][:max_length])
    assert_equal('lib/b.rb', result[1][:location])
    assert_equal(18, result[1][:line])
    assert_equal(80, result[1][:max_length])
  end

  it 'call with custom max length preserves max_length in offense' do
    output = <<~OUTPUT
      lib/example.rb:5: Foo#bar
      100|2:2:1:55
    OUTPUT

    result = parser.call(output)
    assert_equal(100, result.first[:max_length])
  end

  it 'call with empty string returns empty array' do
    assert_equal([], parser.call(''))
  end

  it 'call with nil returns empty array' do
    assert_equal([], parser.call(nil))
  end

  it 'call with malformed output skips invalid lines' do
    output = "not a valid line\n"
    assert_equal([], parser.call(output))
  end
end
