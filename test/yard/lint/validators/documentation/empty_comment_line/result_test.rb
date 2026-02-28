# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationEmptyCommentLineResultTest < Minitest::Test
  attr_reader :config, :parsed_data, :result

  def setup
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::EmptyCommentLine::Result.new(@parsed_data, @config)
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

  def test_class_attributes_defines_default_severity_as_convention
    assert_equal('convention', Yard::Lint::Validators::Documentation::EmptyCommentLine::Result.default_severity)
  end

  def test_class_attributes_defines_offense_type_as_line
    assert_equal('line', Yard::Lint::Validators::Documentation::EmptyCommentLine::Result.offense_type)
  end

  def test_class_attributes_defines_offense_name_as_emptycommentline
    assert_equal('EmptyCommentLine', Yard::Lint::Validators::Documentation::EmptyCommentLine::Result.offense_name)
  end

  def test_build_message_delegates_to_messagesbuilder
    offense = {
      location: 'lib/example.rb',
      line: 5,
      object_line: 10,
      object_name: 'MyClass#process',
      violation_type: 'leading'
    }

    assert_includes(result.build_message(offense), 'leading')
    assert_includes(result.build_message(offense), 'MyClass#process')
  end
end
