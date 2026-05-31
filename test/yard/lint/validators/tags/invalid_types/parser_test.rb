# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::InvalidTypes::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Tags::InvalidTypes::Parser.new
  end

  it 'initialize inherits from parser base class' do
    assert_kind_of(Yard::Lint::Parsers::Base, parser)
  end

  it 'call parses input and returns array' do
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  it 'call handles empty input' do
    result = parser.call('')
    assert_equal([], result)
  end

  it 'call parses location line into offense hash' do
    input = "/path/to/file.rb:10: MyClass#my_method\n@return:BadType"

    result = parser.call(input)

    assert_equal(1, result.size)
    assert_equal('/path/to/file.rb', result.first[:location])
    assert_equal(10, result.first[:line])
    assert_equal('MyClass', result.first[:class_name])
    assert_equal('my_method', result.first[:method_name])
  end

  it 'call parses tag violations from second line' do
    input = "/path/to/file.rb:10: MyClass#my_method\n@return:BadType"

    result = parser.call(input)

    violations = result.first[:tag_violations]
    assert_equal(1, violations.size)
    assert_equal('@return', violations.first[:tag])
    assert_nil(violations.first[:param])
    assert_equal(['BadType'], violations.first[:types])
  end

  it 'call parses tag violation with param name' do
    input = "/path/to/file.rb:10: MyClass#my_method\n@param body:InvalidType"

    result = parser.call(input)

    violation = result.first[:tag_violations].first
    assert_equal('@param', violation[:tag])
    assert_equal('body', violation[:param])
    assert_equal(['InvalidType'], violation[:types])
  end

  it 'call parses multiple tag violations separated by pipe' do
    input = "/path/to/file.rb:10: MyClass#my_method\n@param body:TypeA|@return:TypeB,TypeC"

    result = parser.call(input)

    violations = result.first[:tag_violations]
    assert_equal(2, violations.size)
    assert_equal('@param', violations[0][:tag])
    assert_equal(['TypeA'], violations[0][:types])
    assert_equal('@return', violations[1][:tag])
    assert_equal(['TypeB', 'TypeC'], violations[1][:types])
  end

  it 'call parses multiple offenses' do
    input = "/a.rb:1: A#foo\n@return:Bad\n/b.rb:2: B#bar\n@param x:Wrong"

    result = parser.call(input)

    assert_equal(2, result.size)
    assert_equal('foo', result[0][:method_name])
    assert_equal('bar', result[1][:method_name])
  end
end
