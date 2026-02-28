# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationUndocumentedBooleanMethodsParserTest < Minitest::Test
  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Parser.new
  end

  def test_initialize_inherits_from_parser_base_class
    assert_kind_of(Yard::Lint::Parsers::Base, parser)
  end

  def test_call_parses_input_and_returns_array
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  def test_call_handles_empty_input
    result = parser.call('')
  end
end

