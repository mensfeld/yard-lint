# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationUndocumentedBooleanMethodsResultTest < Minitest::Test
  attr_reader :config, :parsed_data, :result

  def setup
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Result.new(@parsed_data, @config)
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

  def test_class_methods_defines_default_severity
    assert_respond_to(Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Result, :default_severity)
  end

  def test_class_methods_defines_offense_type
    assert_respond_to(Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Result, :offense_type)
  end

  def test_class_methods_defines_offense_name
    assert_respond_to(Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Result, :offense_name)
  end
end
