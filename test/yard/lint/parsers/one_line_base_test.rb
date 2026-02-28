# frozen_string_literal: true

require 'test_helper'

class YardLintParsersOneLineBaseTest < Minitest::Test
  attr_reader :parser, :parser_class

  def setup
    @parser_class = Class.new(Yard::Lint::Parsers::OneLineBase) do
      self.regexps = {
        general: /^Error:/,
        message: /Error: (.+) in/,
        location: /in (.+\.rb) at/,
        line: /line (\d+)/
      }.freeze
    end
    @parser = parser_class.new
  end

  def test_call_parses_matching_lines
    stdout = "Error: Something wrong in file.rb at line 10\n"
    result = parser.call(stdout)

    assert_kind_of(Array, result)
    assert_equal(1, result.size)
    assert_equal('file.rb', result.first[:location])
    assert_equal(10, result.first[:line])
    assert_equal('Something wrong', result.first[:message])
  end

  def test_call_ignores_non_matching_lines
    stdout = "Random text\nNot matching\n"
    result = parser.call(stdout)

    assert_equal([], result)
  end

  def test_call_handles_empty_input
    stdout = ''
    result = parser.call(stdout)

    assert_equal([], result)
  end

  def test_call_handles_multiple_matching_lines
    stdout = "Error: First in file1.rb at line 5\nError: Second in file2.rb at line 10\n"
    result = parser.call(stdout)

    assert_equal(2, result.size)
  end

  def test_inheritance_can_be_subclassed
    assert_kind_of(Yard::Lint::Parsers::OneLineBase, parser)
  end
end
