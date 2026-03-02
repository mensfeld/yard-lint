# frozen_string_literal: true

describe 'Yard::Lint::Parsers::Base' do
  attr_reader :parser_class, :parser

  before do
    @parser_class = Class.new(Yard::Lint::Parsers::Base) do
    self.regexps = {
    test: /(?<value>\d+)/
    }.freeze
    end
    @parser = parser_class.new
  end

  it 'regexps allows setting class level regexps' do
    assert(parser_class.regexps.key?(:test))
  end

  it 'regexps can be accessed via instance' do
  end

  it 'match extracts captures using named regexp' do
    result = parser.match('Value: 123', :test)
  end

  it 'match returns empty array when no match' do
    result = parser.match('No numbers here', :test)
  end

  it 'match returns captures from matched groups' do
    result = parser.match('42', :test)
  end

  it 'inheritance can be subclassed' do
    subclass = Class.new(Yard::Lint::Parsers::Base)
    assert_kind_of(Yard::Lint::Parsers::Base, subclass.new)
  end
end

