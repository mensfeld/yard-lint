# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsExampleStyleResultTest < Minitest::Test

  def test_class_attributes_has_convention_default_severity
    assert_equal('convention', Yard::Lint::Validators::Tags::ExampleStyle::Result.default_severity)
  end

  def test_class_attributes_has_line_offense_type
    assert_equal('line', Yard::Lint::Validators::Tags::ExampleStyle::Result.offense_type)
  end

  def test_class_attributes_has_examplestyleoffense_as_offense_name
    assert_equal('ExampleStyleOffense', Yard::Lint::Validators::Tags::ExampleStyle::Result.offense_name)
  end

  def test_initialize_inherits_from_result_base_class
    result = Yard::Lint::Validators::Tags::ExampleStyle::Result.new([])
    assert_kind_of(Yard::Lint::Results::Base, result)
  end

  def test_initialize_builds_offenses_from_parsed_data
    parsed_data = [
      {
        name: 'ExampleStyle',
        object_name: 'User#initialize',
        example_name: 'Basic usage',
        cop_name: 'Style/StringLiterals',
        message: 'Prefer single-quoted strings',
        location: 'lib/user.rb',
        line: 10
      }
    ]

    result = Yard::Lint::Validators::Tags::ExampleStyle::Result.new(parsed_data)
    assert_equal(1, result.offenses.length)
    assert_equal('convention', result.offenses.first[:severity])
    assert_equal('ExampleStyle', result.offenses.first[:name])
  end

  def test_initialize_respects_configured_severity_from_config
    parsed_data = [
      {
        name: 'ExampleStyle',
        object_name: 'User#initialize',
        example_name: 'Basic usage',
        cop_name: 'Style/StringLiterals',
        message: 'Prefer single-quoted strings',
        location: 'lib/user.rb',
        line: 10
      }
    ]

    config = mock('config')
    config.stubs(:validator_severity).with('Tags/ExampleStyle').returns('warning')

    result = Yard::Lint::Validators::Tags::ExampleStyle::Result.new(parsed_data, config)
    assert_equal('warning', result.offenses.first[:severity])
  end

  def test_build_message_delegates_to_messagesbuilder
    parsed_data = [
      {
        name: 'ExampleStyle',
        object_name: 'User#initialize',
        example_name: 'Basic usage',
        cop_name: 'Style/StringLiterals',
        message: 'Prefer single-quoted strings',
        location: 'lib/user.rb',
        line: 10
      }
    ]

    result = Yard::Lint::Validators::Tags::ExampleStyle::Result.new(parsed_data)
    offense = result.offenses.first

    assert_includes(offense[:message], 'User#initialize')
    assert_includes(offense[:message], 'Style/StringLiterals')
    assert_includes(offense[:message], 'Prefer single-quoted strings')
  end
end
