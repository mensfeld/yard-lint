# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::InformalNotation::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Tags::InformalNotation::Parser.new
  end

  it 'call with valid yard output parses violations correctly' do
    yard_output = <<~OUTPUT
      lib/example.rb:10: MyClass#my_method
      Note|@note|0|Note: This is important
      lib/example.rb:25: AnotherClass
      TODO|@todo|2|TODO: Fix this later
    OUTPUT

    result = parser.call(yard_output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    first = result[0]
    assert_equal('lib/example.rb', first[:location])
    assert_equal(10, first[:line])
    assert_equal('MyClass#my_method', first[:object_name])
    assert_equal('Note', first[:pattern])
    assert_equal('@note', first[:replacement])
    assert_equal(0, first[:line_offset])
    assert_equal('Note: This is important', first[:line_text])

    second = result[1]
    assert_equal('lib/example.rb', second[:location])
    assert_equal(25, second[:line])
    assert_equal('AnotherClass', second[:object_name])
    assert_equal('TODO', second[:pattern])
    assert_equal('@todo', second[:replacement])
    assert_equal(2, second[:line_offset])
    assert_equal('TODO: Fix this later', second[:line_text])
  end

  it 'call with empty output returns empty array for nil' do
    assert_equal([], parser.call(nil))
  end

  it 'call with empty output returns empty array for empty string' do
    assert_equal([], parser.call(''))
  end

  it 'call with empty output returns empty array for whitespace only' do
    assert_equal([], parser.call("  \n  \t  "))
  end

  it 'call with malformed output skips lines without proper format' do
    yard_output = <<~OUTPUT
      malformed line
      another bad line
    OUTPUT

    result = parser.call(yard_output)
    assert_equal([], result)
  end

  it 'call with malformed output skips incomplete violation pairs' do
    yard_output = <<~OUTPUT
      lib/example.rb:10: MyClass#method
    OUTPUT

    result = parser.call(yard_output)
    assert_equal([], result)
  end

  it 'call with missing line text handles missing line text gracefully' do
    yard_output = <<~OUTPUT
      lib/example.rb:10: MyClass#method
      Note|@note|0|
    OUTPUT

    result = parser.call(yard_output)
    assert_equal(1, result.size)
    assert_equal('', result[0][:line_text])
  end
end

