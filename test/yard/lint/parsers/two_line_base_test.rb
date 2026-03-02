# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Parsers::TwoLineBase' do
  attr_reader :parser_class, :parser

  before do
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

  it 'call parses two line patterns' do
    input = "Error: Something wrong\n  in file.rb at line 10\n"
    result = parser.call(input)

    assert_kind_of(Array, result)
  end

  it 'call ignores incomplete patterns' do
    input = "Error: Something\nNot matching second line\n"
    result = parser.call(input)

    assert_equal(1, result.size)
    assert_nil(result.first[:location])
  end

  it 'call handles empty input' do
    result = parser.call('')
  end

  it 'call handles multiple two line patterns' do
    input = "Error: First\n  in file1.rb at line 5\nError: Second\n  in file2.rb at line 10\n"
    result = parser.call(input)
    end
  it 'inheritance can be subclassed' do
    assert_kind_of(Yard::Lint::Parsers::TwoLineBase, parser)
  end
end

