# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsRedundantParamDescriptionResultTest < Minitest::Test

  attr_reader :config

  def setup
    @config = Yard::Lint::Config.new
  end

  def test_class_attributes_has_correct_default_severity
    assert_equal('convention', Yard::Lint::Validators::Tags::RedundantParamDescription::Result.default_severity)
  end

  def test_class_attributes_has_correct_offense_type
    assert_equal('tag', Yard::Lint::Validators::Tags::RedundantParamDescription::Result.offense_type)
  end

  def test_class_attributes_has_correct_offense_name
    assert_equal('RedundantParamDescription', Yard::Lint::Validators::Tags::RedundantParamDescription::Result.offense_name)
  end

  def test_initialize_inherits_from_base_result
    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new([], config)
    assert_kind_of(Yard::Lint::Results::Base, result)
  end

  def test_initialize_stores_config
    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new([], config)
    assert_equal(config, result.config)
  end

  def test_offense_building_with_no_violations_returns_empty_offenses_array
    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new([], config)
    assert_equal([], result.offenses)
  end

  def test_offense_building_with_single_violation_returns_offense_with_all_required_fields
    parsed_data = [{
      name: 'RedundantParamDescription',
      tag_name: 'param',
      param_name: 'user',
      description: 'The user',
      type_name: 'User',
      pattern_type: 'article_param',
      word_count: 2,
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#method'
    }]

    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new(parsed_data, config)
    offense = result.offenses.first

    assert_equal('RedundantParamDescription', offense[:name])
    assert_equal('lib/example.rb', offense[:location])
    assert_equal(10, offense[:location_line])
    assert_equal('convention', offense[:severity])
    assert_kind_of(String, offense[:message])
    assert_includes(offense[:message], 'The user')
  end

  def test_offense_building_with_single_violation_includes_pattern_specific_message
    parsed_data = [{
      name: 'RedundantParamDescription',
      tag_name: 'param',
      param_name: 'user',
      description: 'The user',
      type_name: 'User',
      pattern_type: 'article_param',
      word_count: 2,
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#method'
    }]

    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new(parsed_data, config)
    message = result.offenses.first[:message]

    assert_includes(message, 'redundant')
    assert_includes(message, 'restates the parameter name')
  end

  def test_offense_building_with_single_violation_preserves_object_name_in_offense
    parsed_data = [{
      name: 'RedundantParamDescription',
      tag_name: 'param',
      param_name: 'user',
      description: 'The user',
      type_name: 'User',
      pattern_type: 'article_param',
      word_count: 2,
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#method'
    }]

    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new(parsed_data, config)
    offense = result.offenses.first

    assert_equal('MyClass#method', offense[:object_name])
  end

  def test_offense_building_with_multiple_violations_returns_all_offenses
    parsed_data = [
      {
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'user',
        description: 'The user',
        type_name: 'User',
        pattern_type: 'article_param',
        word_count: 2,
        location: 'lib/example.rb',
        line: 10,
        object_name: 'MyClass#method1'
      },
      {
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'data',
        description: 'The data',
        type_name: 'Hash',
        pattern_type: 'article_param',
        word_count: 2,
        location: 'lib/example.rb',
        line: 20,
        object_name: 'MyClass#method2'
      },
      {
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'payment',
        description: 'Payment object',
        type_name: 'Payment',
        pattern_type: 'type_restatement',
        word_count: 2,
        location: 'lib/other.rb',
        line: 30,
        object_name: 'OtherClass#process'
      }
    ]

    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new(parsed_data, config)
    assert_equal(3, result.offenses.length)
  end

  def test_offense_building_with_multiple_violations_parses_each_offense_correctly
    parsed_data = [
      {
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'user',
        description: 'The user',
        type_name: 'User',
        pattern_type: 'article_param',
        word_count: 2,
        location: 'lib/example.rb',
        line: 10,
        object_name: 'MyClass#method1'
      },
      {
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'data',
        description: 'The data',
        type_name: 'Hash',
        pattern_type: 'article_param',
        word_count: 2,
        location: 'lib/example.rb',
        line: 20,
        object_name: 'MyClass#method2'
      },
      {
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'payment',
        description: 'Payment object',
        type_name: 'Payment',
        pattern_type: 'type_restatement',
        word_count: 2,
        location: 'lib/other.rb',
        line: 30,
        object_name: 'OtherClass#process'
      }
    ]

    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new(parsed_data, config)
    offenses = result.offenses

    assert_equal(10, offenses[0][:location_line])
    assert_equal('lib/example.rb', offenses[0][:location])
    assert_equal('MyClass#method1', offenses[0][:object_name])

    assert_equal(20, offenses[1][:location_line])
    assert_equal('lib/example.rb', offenses[1][:location])

    assert_equal(30, offenses[2][:location_line])
    assert_equal('lib/other.rb', offenses[2][:location])
  end

  def test_offense_building_with_different_pattern_types_generates_different_messages
    parsed_data = [
      {
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'appointment',
        description: 'The appointment',
        type_name: 'Appointment',
        pattern_type: 'article_param',
        word_count: 2,
        location: 'lib/example.rb',
        line: 10,
        object_name: 'MyClass#method1'
      },
      {
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'appointment',
        description: "The event's appointment",
        type_name: 'Appointment',
        pattern_type: 'possessive_param',
        word_count: 3,
        location: 'lib/example.rb',
        line: 20,
        object_name: 'MyClass#method2'
      },
      {
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'user',
        description: 'User object',
        type_name: 'User',
        pattern_type: 'type_restatement',
        word_count: 2,
        location: 'lib/example.rb',
        line: 30,
        object_name: 'MyClass#method3'
      }
    ]

    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new(parsed_data, config)
    messages = result.offenses.map { |o| o[:message] }

    assert_includes(messages[0], 'restates the parameter name')
    assert_includes(messages[1], 'adds no meaningful information')
    assert_includes(messages[2], 'repeats the type name')
  end

  def test_severity_defaults_to_convention
    parsed_data = [{
      name: 'RedundantParamDescription',
      tag_name: 'param',
      param_name: 'user',
      description: 'The user',
      type_name: 'User',
      pattern_type: 'article_param',
      word_count: 2,
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#method'
    }]

    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new(parsed_data, config)
    assert_equal('convention', result.offenses.first[:severity])
  end

  def test_offense_structure_includes_all_required_offense_keys
    parsed_data = [{
      name: 'RedundantParamDescription',
      tag_name: 'param',
      param_name: 'user',
      description: 'The user',
      type_name: 'User',
      pattern_type: 'article_param',
      word_count: 2,
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#method'
    }]

    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new(parsed_data, config)
    offense = result.offenses.first

    assert(offense.key?(:name))
    assert(offense.key?(:location))
    assert(offense.key?(:location_line))
    assert(offense.key?(:severity))
    assert(offense.key?(:message))
    assert(offense.key?(:object_name))
  end

  def test_offense_structure_has_correct_offense_name
    parsed_data = [{
      name: 'RedundantParamDescription',
      tag_name: 'param',
      param_name: 'user',
      description: 'The user',
      type_name: 'User',
      pattern_type: 'article_param',
      word_count: 2,
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#method'
    }]

    result = Yard::Lint::Validators::Tags::RedundantParamDescription::Result.new(parsed_data, config)
    assert_equal('RedundantParamDescription', result.offenses.first[:name])
  end
end
