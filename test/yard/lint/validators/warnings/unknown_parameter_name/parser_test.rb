# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsWarningsUnknownParameterNameParserTest < Minitest::Test
  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.new
  end

  def test_initialize_inherits_from_twolinebase_parser
    assert_kind_of(Yard::Lint::Parsers::TwoLineBase, parser)
  end

  def test_regexps_defines_required_regexps
    assert_kind_of(Hash, Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.regexps)
    assert(Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.regexps.key?(:general))
    assert(Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.regexps.key?(:message))
    assert(Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.regexps.key?(:location))
    assert(Yard::Lint::Validators::Warnings::UnknownParameterName::Parser.regexps.key?(:line))
  end

  def test_call_parses_input_and_returns_array
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  def test_call_handles_empty_input
    result = parser.call('')
  end
end

