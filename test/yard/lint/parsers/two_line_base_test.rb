# frozen_string_literal: true

require 'test_helper'

class YardLintParsersTwoLineBaseTest < Minitest::Test
  attr_reader :parser, :parser_class


  def setup
    @parser_class = Class.new(Yard::Lint::Parsers::TwoLineBase) do
    self.regexps = {
    general: /^Error:/,
    message: /^Error: (.+)$/,
    location: /^  in (.+\.rb) at line/,
    line: /^  in .+ at line (\d+)$/
    }.freeze
    end
    @parser = parser_class.new
  end

  def test_call_parses_two_line_patterns
    input = "Error: Something wrong\n  in file.rb at line 10\n"
    result = parser.call(input)

    assert_kind_of(Array, result)
  end

  def test_call_ignores_incomplete_patterns
    input = "Error: Something\nNot matching second line\n"
    result = parser.call(input)

    assert_equal(1, result.size)
    assert_nil(result.first[:location])
  end

  def test_call_handles_empty_input
    result = parser.call('')
  end

  def test_call_handles_multiple_two_line_patterns
    input = "Error: First\n  in file1.rb at line 5\nError: Second\n  in file2.rb at line 10\n"
    result = parser.call(input)
    end
  def test_inheritance_can_be_subclassed
    assert_kind_of(Yard::Lint::Parsers::TwoLineBase, parser)
  end
end

