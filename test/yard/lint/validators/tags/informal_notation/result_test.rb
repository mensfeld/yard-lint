# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsInformalNotationResultTest < Minitest::Test

  def test_class_attributes_has_default_severity_set_to_warning
    assert_equal('warning', Yard::Lint::Validators::Tags::InformalNotation::Result.default_severity)
  end

  def test_class_attributes_has_offense_type_set_to_line
    assert_equal('line', Yard::Lint::Validators::Tags::InformalNotation::Result.offense_type)
  end

  def test_class_attributes_has_offense_name_set_to_informalnotation
    assert_equal('InformalNotation', Yard::Lint::Validators::Tags::InformalNotation::Result.offense_name)
  end

  def test_build_message_delegates_to_messagesbuilder
    offense = {
      pattern: 'Note',
      replacement: '@note',
      line_text: 'Note: This is important'
    }

    Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder.stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::InformalNotation::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  def test_inheritance_inherits_from_results_base
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::InformalNotation::Result.superclass)
  end
end
