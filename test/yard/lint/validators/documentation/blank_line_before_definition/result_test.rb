# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationBlankLineBeforeDefinitionResultTest < Minitest::Test
  attr_reader :config, :parsed_data, :result

  def setup
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.new(@parsed_data, @config)
  end

  def test_initialize_inherits_from_results_base
    assert_kind_of(Yard::Lint::Results::Base, @result)
  end

  def test_initialize_stores_config
    assert_equal(@config, @result.instance_variable_get(:@config))
  end

  def test_offenses_returns_an_array
    assert_kind_of(Array, @result.offenses)
  end

  def test_offenses_handles_empty_parsed_data
    assert_equal([], @result.offenses)
  end

  def test_class_defines_default_severity_as_convention
    assert_equal('convention', Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.default_severity)
  end

  def test_class_defines_offense_type_as_line
    assert_equal('line', Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.offense_type)
  end

  def test_class_defines_offense_name_as_blank_line_before_definition
    assert_equal('BlankLineBeforeDefinition', Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.offense_name)
  end

  def test_build_message_delegates_to_messages_builder
    offense = {
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#process',
      violation_type: 'single',
      blank_count: 1
    }

    assert_includes(@result.build_message(offense), 'Blank line')
    assert_includes(@result.build_message(offense), 'MyClass#process')
  end

  def test_severity_for_single_blank_line_uses_default
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 10,
        object_name: 'MyClass#process',
        violation_type: 'single',
        blank_count: 1
      }
    ]

    result = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.new(parsed_data, @config)
    assert_equal('convention', result.offenses.first[:severity])
  end

  def test_severity_for_orphaned_documentation_uses_orphaned_severity
    parsed_data = [
      {
        location: 'lib/example.rb',
        line: 15,
        object_name: 'MyClass#execute',
        violation_type: 'orphaned',
        blank_count: 2
      }
    ]

    result = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Result.new(parsed_data, @config)
    assert_equal('convention', result.offenses.first[:severity])
  end
end
