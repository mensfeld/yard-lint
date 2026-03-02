# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::ForbiddenTags::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Tags::ForbiddenTags::Parser.new
  end

  it 'call with valid yard output parses violations correctly' do
    yard_output = <<~OUTPUT
      lib/example.rb:10: void_return
      return|void|void
      lib/example.rb:25: object_param
      param|Object|Object
    OUTPUT

    result = parser.call(yard_output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    first = result[0]
    assert_equal('lib/example.rb', first[:location])
    assert_equal(10, first[:line])
    assert_equal('void_return', first[:object_name])
    assert_equal('return', first[:tag_name])
    assert_equal('void', first[:types_text])
    assert_equal('void', first[:pattern_types])

    second = result[1]
    assert_equal('lib/example.rb', second[:location])
    assert_equal(25, second[:line])
    assert_equal('object_param', second[:object_name])
    assert_equal('param', second[:tag_name])
    assert_equal('Object', second[:types_text])
    assert_equal('Object', second[:pattern_types])
  end

  it 'call with tag only pattern no types parses violations with empty types' do
    yard_output = <<~OUTPUT
      lib/example.rb:15: ApiClass
      api||
    OUTPUT

    result = parser.call(yard_output)

    assert_equal(1, result.size)
    assert_equal('api', result[0][:tag_name])
    assert_equal('', result[0][:types_text])
    assert_equal('', result[0][:pattern_types])
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
      lib/example.rb:10: void_return
    OUTPUT

    result = parser.call(yard_output)
    assert_equal([], result)
  end
end

