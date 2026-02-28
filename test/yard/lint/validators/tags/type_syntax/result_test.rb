# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTypeSyntaxResultTest < Minitest::Test

  def test_class_attributes_has_default_severity_set_to_warning
    assert_equal('warning', Yard::Lint::Validators::Tags::TypeSyntax::Result.default_severity)
  end

  def test_class_attributes_has_offense_type_set_to_method
    assert_equal('method', Yard::Lint::Validators::Tags::TypeSyntax::Result.offense_type)
  end

  def test_class_attributes_has_offense_name_set_to_invalidtypesyntax
    assert_equal('InvalidTypeSyntax', Yard::Lint::Validators::Tags::TypeSyntax::Result.offense_name)
  end

  def test_build_message_delegates_to_messagesbuilder
    offense = {
      tag_name: 'param',
      type_string: 'Array<',
      error_message: "expecting name, got ''"
    }

    Yard::Lint::Validators::Tags::TypeSyntax::MessagesBuilder
      .stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::TypeSyntax::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  def test_inheritance_inherits_from_results_base
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::TypeSyntax::Result.superclass)
  end
end
