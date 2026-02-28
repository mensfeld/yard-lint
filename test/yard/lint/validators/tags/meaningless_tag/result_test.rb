# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsMeaninglessTagResultTest < Minitest::Test

  def test_class_attributes_has_default_severity_set_to_warning
    assert_equal('warning', Yard::Lint::Validators::Tags::MeaninglessTag::Result.default_severity)
  end

  def test_class_attributes_has_offense_type_set_to_class
    assert_equal('class', Yard::Lint::Validators::Tags::MeaninglessTag::Result.offense_type)
  end

  def test_class_attributes_has_offense_name_set_to_meaninglesstag
    assert_equal('MeaninglessTag', Yard::Lint::Validators::Tags::MeaninglessTag::Result.offense_name)
  end

  def test_build_message_delegates_to_messagesbuilder
    offense = {
      object_type: 'class',
      tag_name: 'param',
      object_name: 'InvalidClass'
    }

    Yard::Lint::Validators::Tags::MeaninglessTag::MessagesBuilder
      .stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::MeaninglessTag::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  def test_inheritance_inherits_from_results_base
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::MeaninglessTag::Result.superclass)
  end
end
