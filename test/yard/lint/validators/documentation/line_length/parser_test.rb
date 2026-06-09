# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::LineLength::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Documentation::LineLength::Parser.new
  end

  it 'call with single violation parses one over-length line' do
    output = <<~OUTPUT
      lib/example.rb:10: MyClass#process
      5:135
    OUTPUT

    result = parser.call(output)

    assert_equal(
      [
        {
          location: 'lib/example.rb',
          line: 5,
          object_line: 10,
          object_name: 'MyClass#process',
          length: 135
        }
      ],
      result
    )
  end

  it 'call with multiple violations on same object parses all lines' do
    output = <<~OUTPUT
      lib/example.rb:15: MyClass#execute
      3:125|4:140
    OUTPUT

    result = parser.call(output)

    assert_equal(
      [
        {
          location: 'lib/example.rb',
          line: 3,
          object_line: 15,
          object_name: 'MyClass#execute',
          length: 125
        },
        {
          location: 'lib/example.rb',
          line: 4,
          object_line: 15,
          object_name: 'MyClass#execute',
          length: 140
        }
      ],
      result
    )
  end

  it 'call with multiple objects parses violations from both objects' do
    output = <<~OUTPUT
      lib/a.rb:10: Foo#bar
      2:130
      lib/b.rb:20: Baz#qux
      18:150|19:160
    OUTPUT

    result = parser.call(output)

    assert_equal(3, result.size)
    assert_equal('lib/a.rb', result[0][:location])
    assert_equal(2, result[0][:line])
    assert_equal(130, result[0][:length])
    assert_equal('lib/b.rb', result[1][:location])
    assert_equal(18, result[1][:line])
    assert_equal(150, result[1][:length])
    assert_equal(19, result[2][:line])
    assert_equal(160, result[2][:length])
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
