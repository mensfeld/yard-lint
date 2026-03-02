# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::TagGroupSeparator::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Tags::TagGroupSeparator::Parser.new
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

  it 'call handles nil input' do
    result = parser.call(nil)
    assert_equal([], result)
  end

  it 'call with valid entries filters out valid entries' do
    input = <<~OUTPUT
      lib/example.rb:10: Example#method
      valid
    OUTPUT

    result = parser.call(input)
    assert_empty(result)
  end

  it 'call with offense entries parses offense entries' do
    input = <<~OUTPUT
      lib/example.rb:10: Example#method
      param->return
    OUTPUT

    result = parser.call(input)
    assert_equal(1, result.size)
    assert_equal('lib/example.rb', result.first[:location])
    assert_equal(10, result.first[:line])
    assert_equal('method', result.first[:method_name])
    assert_equal('param->return', result.first[:separators])
  end

  it 'call with multiple offenses parses all offense entries' do
    input = <<~OUTPUT
      lib/example.rb:10: Example#method1
      param->return
      lib/example.rb:20: Example#method2
      return->error,error->example
    OUTPUT

    result = parser.call(input)
    assert_equal(2, result.size)
    assert_equal('method1', result[0][:method_name])
    assert_equal('param->return', result[0][:separators])
    assert_equal('method2', result[1][:method_name])
    assert_equal('return->error,error->example', result[1][:separators])
  end
end

