# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::Order::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Tags::Order::Parser.new
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
  end

  it 'call pairs each offense with its own expected order' do
    raw = <<~OUTPUT
      lib/example.rb:5: Example#first
      param,return
      lib/example.rb:20: Example#second
      return,example
    OUTPUT

    result = parser.call(result: raw)

    assert_equal(2, result.size)
    assert_equal('param,return', result.find { |o| o[:method_name] == 'first' }[:order])
    assert_equal('return,example', result.find { |o| o[:method_name] == 'second' }[:order])
  end

  it 'call keeps pairing intact when a location line is unparseable' do
    raw = <<~OUTPUT
      lib/example.rb:5: Example#first
      param,return
      THIS LINE IS NOT A LOCATION
      example,param
      lib/example.rb:20: Example#second
      return,example
    OUTPUT

    result = parser.call(result: raw)

    assert_equal(2, result.size)

    second = result.find { |o| o[:method_name] == 'second' }

    refute_nil(second)
    # The unparseable entry must be dropped alone - it must not shift the
    # expected-order payloads of the offenses that follow it
    assert_equal('return,example', second[:order])
  end
end

