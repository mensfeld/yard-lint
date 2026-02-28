# frozen_string_literal: true

require 'test_helper'

class YardLintParsersBaseTest < Minitest::Test
  attr_reader :parser, :parser_class

  def setup
    @parser_class = Class.new(Yard::Lint::Parsers::Base) do
    self.regexps = {
    test: /(?<value>\d+)/
    }.freeze
    end
    @parser = parser_class.new
  end

  def test_regexps_allows_setting_class_level_regexps
    assert(parser_class.regexps.key?(:test))
  end

  def test_regexps_can_be_accessed_via_instance
  end

  def test_match_extracts_captures_using_named_regexp
    result = parser.match('Value: 123', :test)
  end

  def test_match_returns_empty_array_when_no_match
    result = parser.match('No numbers here', :test)
  end

  def test_match_returns_captures_from_matched_groups
    result = parser.match('42', :test)
  end

  def test_inheritance_can_be_subclassed
    subclass = Class.new(Yard::Lint::Parsers::Base)
    assert_kind_of(Yard::Lint::Parsers::Base, subclass.new)
  end
end

