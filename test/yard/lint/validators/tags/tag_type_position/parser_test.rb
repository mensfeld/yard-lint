# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::TagTypePosition::Parser' do
  attr_reader :parser


  before do
    @parser = Yard::Lint::Validators::Tags::TagTypePosition::Parser.new
  end

  it 'call with valid yard output parses violations correctly' do
    output = <<~OUTPUT
      lib/example.rb:25: User#initialize
      param|name|String|type_after_name
      lib/example.rb:35: Order#process
      option|opts|Hash|type_first
    OUTPUT

    result = parser.call(output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    assert_equal('lib/example.rb', result[0][:location])
    assert_equal(25, result[0][:line])
    assert_equal('User#initialize', result[0][:object_name])
    assert_equal('param', result[0][:tag_name])
    assert_equal('name', result[0][:param_name])
    assert_equal('String', result[0][:type_info])
    assert_equal('type_after_name', result[0][:detected_style])

    assert_equal('lib/example.rb', result[1][:location])
    assert_equal(35, result[1][:line])
    assert_equal('Order#process', result[1][:object_name])
    assert_equal('option', result[1][:tag_name])
    assert_equal('opts', result[1][:param_name])
    assert_equal('Hash', result[1][:type_info])
    assert_equal('type_first', result[1][:detected_style])
  end

  it 'call with valid yard output handles violations without detected style' do
    output = <<~OUTPUT
      lib/test.rb:10: Test#method
      param|value|Integer
    OUTPUT

    result = parser.call(output)

    assert_equal(1, result.size)
    assert_equal('lib/test.rb', result[0][:location])
    assert_equal(10, result[0][:line])
    assert_equal('Test#method', result[0][:object_name])
    assert_equal('param', result[0][:tag_name])
    assert_equal('value', result[0][:param_name])
    assert_equal('Integer', result[0][:type_info])
    assert_nil(result[0][:detected_style])
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

  it 'call with malformed output skips lines without proper location format' do
    output = <<~OUTPUT
      invalid location line
      param|name|String|type_after_name
      lib/example.rb:25: Valid#method
      param|value|Integer|type_first
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.size)
    assert_equal('Valid#method', result[0][:object_name])
  end

  it 'call with malformed output skips incomplete violation pairs' do
    output = "lib/example.rb:10: Test#method\n"
    result = parser.call(output)
    assert_equal([], result)
  end

  it 'call with malformed output skips details with insufficient fields' do
    output = <<~OUTPUT
      lib/example.rb:10: Test#method
      param|name
    OUTPUT

    result = parser.call(output)
    assert_equal([], result)
  end
end
