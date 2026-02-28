# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationMissingReturnResultTest < Minitest::Test
  attr_reader :config, :parsed_data, :result

  def setup
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::MissingReturn::Result.new(@parsed_data, @config)
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

  def test_offenses_with_parsed_data_builds_offenses_from_parsed_data
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        element: 'Calculator#add'
      }
    ]
    result = Yard::Lint::Validators::Documentation::MissingReturn::Result.new(parsed_data, config)

    offenses = result.offenses
    refute_empty(offenses)
    assert_equal('lib/example.rb', offenses.first[:location])
    assert_equal(10, offenses.first[:location_line])
    assert_equal('MissingReturnTag', offenses.first[:name])
  end

  def test_offenses_with_parsed_data_includes_message_from_messagesbuilder
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        element: 'Calculator#add'
      }
    ]
    result = Yard::Lint::Validators::Documentation::MissingReturn::Result.new(parsed_data, config)

    offenses = result.offenses
    assert_includes(offenses.first[:message], 'Missing @return tag for `Calculator#add`')
  end

  def test_offenses_with_parsed_data_sets_offense_type_to_line
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        element: 'Calculator#add'
      }
    ]
    result = Yard::Lint::Validators::Documentation::MissingReturn::Result.new(parsed_data, config)

    offenses = result.offenses
    assert_equal('line', offenses.first[:type])
  end

  def test_offenses_with_parsed_data_sets_default_severity_to_warning
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        element: 'Calculator#add'
      }
    ]
    result = Yard::Lint::Validators::Documentation::MissingReturn::Result.new(parsed_data, config)

    offenses = result.offenses
    assert_equal('warning', offenses.first[:severity])
  end

  def test_class_methods_defines_default_severity
    assert_respond_to(Yard::Lint::Validators::Documentation::MissingReturn::Result, :default_severity)
  end

  def test_class_methods_defines_offense_type
    assert_respond_to(Yard::Lint::Validators::Documentation::MissingReturn::Result, :offense_type)
  end

  def test_class_methods_defines_offense_name
    assert_respond_to(Yard::Lint::Validators::Documentation::MissingReturn::Result, :offense_name)
  end

  def test_class_methods_returns_warning_as_default_severity
    assert_equal('warning', Yard::Lint::Validators::Documentation::MissingReturn::Result.default_severity)
  end

  def test_class_methods_returns_line_as_offense_type
    assert_equal('line', Yard::Lint::Validators::Documentation::MissingReturn::Result.offense_type)
  end

  def test_class_methods_returns_missingreturntag_as_offense_name
    assert_equal('MissingReturnTag', Yard::Lint::Validators::Documentation::MissingReturn::Result.offense_name)
  end

  def test_build_message_delegates_to_messagesbuilder
    offense = { element: 'Example#method' }

    Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder
      .expects(:call).with(offense).returns('test message')

    result.build_message(offense)
  end
end
