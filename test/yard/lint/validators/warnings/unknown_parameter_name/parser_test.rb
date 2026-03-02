# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Warnings::UnknownParameterName::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.new
  end

  it 'initialize inherits from twolinebase parser' do
    assert_kind_of(Yard::Lint::Parsers::TwoLineBase, parser)
  end

  it 'regexps defines required regexps' do
    assert_kind_of(Hash, Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.regexps)
    assert(Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.regexps.key?(:general))
    assert(Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.regexps.key?(:message))
    assert(Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.regexps.key?(:location))
    assert(Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.regexps.key?(:line))
  end

  it 'call parses input and returns array' do
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  it 'call handles empty input' do
    result = parser.call('')
  end
end

