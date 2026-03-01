# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Parsers::OneLineBase' do
  attr_reader :parser_class, :parser


  before do
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

  it 'call parses matching lines' do
    stdout = "Error: Something wrong in file.rb at line 10\n"
    result = parser.call(stdout)

    assert_kind_of(Array, result)
    assert_equal(1, result.size)
    assert_equal('file.rb', result.first[:location])
    assert_equal(10, result.first[:line])
    assert_equal('Something wrong', result.first[:message])
  end

  it 'call ignores non matching lines' do
    stdout = "Random text\nNot matching\n"
    result = parser.call(stdout)

    assert_equal([], result)
  end

  it 'call handles empty input' do
    stdout = ''
    result = parser.call(stdout)

    assert_equal([], result)
  end

  it 'call handles multiple matching lines' do
    stdout = "Error: First in file1.rb at line 5\nError: Second in file2.rb at line 10\n"
    result = parser.call(stdout)

    assert_equal(2, result.size)
  end

  it 'inheritance can be subclassed' do
    assert_kind_of(Yard::Lint::Parsers::OneLineBase, parser)
  end
end
