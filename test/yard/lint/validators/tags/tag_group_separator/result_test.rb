# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTagGroupSeparatorResultTest < Minitest::Test

  attr_reader :config, :parsed_data, :result

  def setup
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Tags::TagGroupSeparator::Result.new(@parsed_data, @config)
  end

  def test_initialize_inherits_from_results_base
    assert_kind_of(Yard::Lint::Results::Base, result)
  end

  def test_initialize_stores_config
    assert_equal(config, result.instance_variable_get(:@config))
  end

  def test_offenses_returns_an_array
    assert_kind_of(Array, result.offenses)
  end

  def test_offenses_handles_empty_parsed_data
    assert_equal([], result.offenses)
  end

  def test_class_methods_defines_default_severity_as_convention
    assert_equal('convention', Yard::Lint::Validators::Tags::TagGroupSeparator::Result.default_severity)
  end

  def test_class_methods_defines_offense_type_as_method
    assert_equal('method', Yard::Lint::Validators::Tags::TagGroupSeparator::Result.offense_type)
  end

  def test_class_methods_defines_offense_name_as_missingtaggroupseparator
    assert_equal('MissingTagGroupSeparator', Yard::Lint::Validators::Tags::TagGroupSeparator::Result.offense_name)
  end

  def test_build_message_generates_human_readable_message
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        method_name: 'call',
        separators: 'param->return'
      }
    ]
    r = Yard::Lint::Validators::Tags::TagGroupSeparator::Result.new(parsed_data, config)
    offense = r.offenses.first
    assert_includes(offense[:message], 'call')
    assert_includes(offense[:message], 'param')
    assert_includes(offense[:message], 'return')
  end
end
