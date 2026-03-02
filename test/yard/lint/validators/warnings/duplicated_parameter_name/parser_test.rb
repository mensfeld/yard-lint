# frozen_string_literal: true

describe 'Yard::Lint::Validators::Warnings::DuplicatedParameterName::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Warnings::DuplicatedParameterName::Parser.new
  end

  it 'initialize inherits from onelinebase parser' do
    assert_kind_of(Yard::Lint::Parsers::OneLineBase, parser)
  end

  it 'regexps defines required regexps' do
    assert_kind_of(Hash, Yard::Lint::Validators::Warnings::DuplicatedParameterName::Parser.regexps)
    assert(Yard::Lint::Validators::Warnings::DuplicatedParameterName::Parser.regexps.key?(:general))
    assert(Yard::Lint::Validators::Warnings::DuplicatedParameterName::Parser.regexps.key?(:message))
    assert(Yard::Lint::Validators::Warnings::DuplicatedParameterName::Parser.regexps.key?(:location))
    assert(Yard::Lint::Validators::Warnings::DuplicatedParameterName::Parser.regexps.key?(:line))
  end

  it 'call parses input and returns array' do
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  it 'call handles empty input' do
    result = parser.call('')
  end
end

