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
end

