# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationUndocumentedOptionsResultTest < Minitest::Test
  attr_reader :config, :parsed_data, :result

  def setup
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.new(parsed_data, config)
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

  def test_offenses_formats_message_for_offense_with_options_parameter
    parsed_offense = {
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#process',
      params: 'data, options = {}'
    }
    result_with_offense = Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.new([parsed_offense], config)
    built_offense = result_with_offense.offenses.first

    assert_equal(
      "Method 'MyClass#process' has options parameter (data, options = {}) " \
      'but no @option tags in documentation.',
      built_offense[:message]
    )
  end

  def test_offenses_formats_message_for_offense_with_kwargs
    parsed_offense = {
      location: 'lib/example.rb',
      line: 15,
      object_name: 'MyClass#configure',
      params: '**options'
    }
    result_with_offense = Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.new([parsed_offense], config)
    built_offense = result_with_offense.offenses.first

    assert_equal(
      "Method 'MyClass#configure' has options parameter (**options) " \
      'but no @option tags in documentation.',
      built_offense[:message]
    )
  end

  def test_class_methods_has_correct_default_severity
    assert_equal('warning', Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.default_severity)
  end

  def test_class_methods_has_correct_offense_type
    assert_equal('line', Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.offense_type)
  end

  def test_class_methods_has_correct_offense_name
    assert_equal('UndocumentedOptions', Yard::Lint::Validators::Documentation::UndocumentedOptions::Result.offense_name)
  end
end
